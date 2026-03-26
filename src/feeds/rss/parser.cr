module Feeds
  module RSS
    class Parser
      include Shared::ExtensionParser

      def parse(content : String) : Feeds::Feed
        doc = XML.parse(content)
        root = find_root(doc)
        feed = Feeds::Feed.new(FeedType::RSS)
        parse_root(root, feed)
        feed
      rescue XML::Error
        raise ParseError.new
      end

      private def parse_root(root : XML::Node, feed : Feeds::Feed)
        case root.name
        when Namespaces::RSS
          feed.feed_version = root[VERSION_ATTR]? || ""
          root.children.each do |node|
            next unless node.element?
            if node.name == CHANNEL_ELEM
              parse_channel(node, feed)
              break
            end
          end
        when RDF_ROOT
          feed.feed_version = rdf_version(root)
          root.children.each do |node|
            next unless node.element?
            case node.name
            when CHANNEL_ELEM then parse_channel(node, feed)
            when ITEM_ELEM    then feed.items << parse_item(node)
            end
          end
        end
      end

      private def rdf_version(root : XML::Node) : String
        root.namespaces.each do |_prefix, uri|
          next if uri.nil?
          return VERSION_10 if uri == Namespaces::RDF_10_URI
          return VERSION_09 if uri == Namespaces::RDF_09_URI || uri == Namespaces::RDF_09B_URI
        end
        ""
      end

      # ameba:disable Metrics/CyclomaticComplexity
      private def parse_channel(node : XML::Node, feed : Feeds::Feed)
        managing_editor = nil
        web_master = nil

        node.children.each do |child|
          next unless child.element?
          prefix = canonical_prefix(child)
          case {prefix, child.name}
          when {"", TITLE_ELEM}           then feed.title = child.content.strip
          when {"", LINK_ELEM}            then set_link(feed, child)
          when {"", DESCRIPTION_ELEM}     then feed.description = child.content.strip
          when {"", LANGUAGE_ELEM}        then feed.language = child.content.strip
          when {"", COPYRIGHT_ELEM}       then feed.copyright = child.content.strip
          when {"", MANAGING_EDITOR_ELEM} then managing_editor = child.content.strip
          when {"", WEB_MASTER_ELEM}      then web_master = child.content.strip
          when {"", PUB_DATE_ELEM}
            raw = child.content.strip
            feed.published = raw
            feed.published_parsed = ::DateParse.parse(raw)
          when {"", LAST_BUILD_DATE_ELEM}
            raw = child.content.strip
            feed.updated = raw
            feed.updated_parsed = ::DateParse.parse(raw)
          when {"", GENERATOR_ELEM}          then feed.generator = child.content.strip
          when {"", CATEGORY_ELEM}           then feed.categories << (parse_rss_category(child).value || "")
          when {"", IMAGE_ELEM}              then feed.image = parse_rss_image(child)
          when {"", ITEM_ELEM}               then feed.items << parse_item(node: child)
          when {Namespaces::ATOM, LINK_ELEM} then parse_atom_link(child, feed.links)
          else
            parse_extension(child, prefix, Namespaces::RSS_KNOWN, feed.extensions)
          end
        end

        finalize_feed_level_extensions(feed)
        finalize_rss_channel(feed, managing_editor, web_master)
      end

      private def finalize_rss_channel(feed : Feeds::Feed, managing_editor : String?, web_master : String?)
        dc = feed.dublin_core_ext
        feed.description ||= itunes_field(feed, &.summary) || itunes_field(feed, &.subtitle)
        feed.language ||= dc.try(&.language.first?)
        feed.copyright ||= dc.try(&.rights.first?)
        feed.updated_parsed ||= dc_date(dc)
        feed.updated ||= dc.try(&.date.first?)

        feed.authors = resolve_authors(
          managing_editor || web_master,
          dc.try { |dc_ext| dc_ext.author.first? || dc_ext.creator.first? },
          itunes_field(feed, &.author)
        )

        native_cats = feed.categories
        feed.categories = translate_categories(native_cats, dc.try(&.subject) || [] of String, feed.itunes_ext)
      end

      # ameba:disable Metrics/CyclomaticComplexity
      private def parse_item(node : XML::Node) : Feeds::Item
        item = Feeds::Item.new
        author_raw = nil
        guid_obj = nil

        node.children.each do |child|
          next unless child.element?
          prefix = canonical_prefix(child)
          case {prefix, child.name}
          when {"", TITLE_ELEM}       then item.title = child.content.strip
          when {"", LINK_ELEM}        then set_link(item, child)
          when {"", DESCRIPTION_ELEM} then item.description = child.content.strip
          when {"", AUTHOR_ELEM}      then author_raw = child.content.strip
          when {"", CATEGORY_ELEM}    then item.categories << (parse_rss_category(child).value || "")
          when {"", PUB_DATE_ELEM}
            raw = child.content.strip
            item.published = raw
            item.published_parsed = ::DateParse.parse(raw)
          when {"", GUID_ELEM}                     then guid_obj = parse_guid(child)
          when {"", ENCLOSURE_ELEM}                then item.enclosures << parse_rss_enclosure(child)
          when {Namespaces::CONTENT, ENCODED_ELEM} then item.content = child.content.strip
          when {Namespaces::ATOM, LINK_ELEM}       then parse_atom_link(child, item.links)
          else
            item.custom[child.name] = child.content.strip if prefix.empty?
            parse_extension(child, prefix, Namespaces::RSS_KNOWN, item.extensions) unless prefix.empty?
          end
        end

        finalize_item_level_extensions(item)
        finalize_rss_item(item, author_raw, guid_obj)
        item
      end

      private def finalize_rss_item(item : Feeds::Item, author_raw : String?, guid_obj : GUID?)
        dc = item.dublin_core_ext
        item.title ||= dc.try(&.title.first?)
        item.description ||= dc.try(&.description.first?) || item.itunes_ext.try(&.summary)
        item.published ||= dc.try(&.date.first?)
        item.published_parsed ||= dc_date(dc)
        item.guid = guid_obj.try(&.value)

        item.authors = resolve_authors(
          author_raw,
          dc.try { |dc_ext| dc_ext.author.first? || dc_ext.creator.first? },
          item.itunes_ext.try(&.author)
        )

        item.categories = translate_categories(item.categories, dc.try(&.subject) || [] of String, item.itunes_ext)
      end

      private def parse_rss_category(node : XML::Node) : Category
        Category.new(domain: node[DOMAIN_ATTR]?, value: node.content.strip)
      end

      private def parse_guid(node : XML::Node) : GUID
        GUID.new(is_permalink: node[IS_PERMALINK_ATTR]?, value: node.content.strip)
      end

      private def parse_rss_enclosure(node : XML::Node) : Feeds::Enclosure
        Feeds::Enclosure.new(url: node[URL_ATTR]?, length: node[LENGTH_ATTR]?, type: node[TYPE_ATTR]?)
      end

      private def parse_rss_image(node : XML::Node) : Feeds::Image
        img = Feeds::Image.new
        node.children.each do |child|
          next unless child.element?
          case child.name
          when URL_ELEM    then img.url = child.content.strip
          when LINK_ELEM   then img.link = child.content.strip
          when TITLE_ELEM  then img.title = child.content.strip
          when WIDTH_ELEM  then img.width = child.content.strip
          when HEIGHT_ELEM then img.height = child.content.strip
          end
        end
        img
      end

      private def parse_atom_link(node : XML::Node, links : Array(String))
        href = node[HREF_ATTR]? || ""
        links << href unless href.empty?
      end

      private def set_link(target, node : XML::Node)
        href = node.content.strip
        return if href.empty?
        target.link = href if target.link.nil?
        target.links << href
      end

      # Resolves the author from multiple RSS sources (raw string, Dublin Core, iTunes)
      private def resolve_authors(
        raw : String?,
        dc_fallback : String?,
        itunes_author : String?,
      ) : Array(Feeds::Person)
        if source = raw.presence
          person = parse_name_address(source)
          return [person] if person.name || person.email
        end
        source = dc_fallback || itunes_author
        return [] of Feeds::Person unless source
        [Feeds::Person.new(name: source)]
      end

      # Parses "email (Name)" or "Name (email@...)" into a Feeds::Person
      private def parse_name_address(s : String) : Feeds::Person
        if m = s.match(/^([^(]+)\s+\(([^)]+)\)$/)
          left, right = m[1].strip, m[2].strip
          if left.includes?('@')
            Feeds::Person.new(email: left, name: right)
          elsif right.includes?('@')
            Feeds::Person.new(name: left, email: right)
          else
            Feeds::Person.new(name: left)
          end
        elsif s.includes?('@')
          Feeds::Person.new(email: s.strip)
        else
          Feeds::Person.new(name: s.strip)
        end
      end
    end
  end
end
