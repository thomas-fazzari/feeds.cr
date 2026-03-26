module Feeds
  module Atom
    class Parser
      include Shared::ExtensionParser

      def parse(content : String) : Feeds::Feed
        doc = XML.parse(content)
        root = find_root(doc)
        feed = Feeds::Feed.new(FeedType::Atom)
        feed.feed_version = VERSION
        feed.language = extract_xml_lang(root)
        parse_feed(root, feed)
        feed
      rescue XML::Error
        raise ParseError.new
      end

      # ameba:disable Metrics/CyclomaticComplexity
      private def parse_feed(root : XML::Node, feed : Feeds::Feed)
        links = [] of Link
        atom_authors = [] of Feeds::Person
        atom_cats = [] of Category
        generator = nil

        root.children.each do |child|
          next unless child.element?
          prefix = canonical_prefix(child)
          case {prefix, child.name}
          when {"", TITLE_ELEM}, {Namespaces::ATOM, TITLE_ELEM}
            feed.title = text_content(child)
          when {"", SUBTITLE_ELEM}, {Namespaces::ATOM, SUBTITLE_ELEM}
            feed.description = text_content(child)
          when {"", ID_ELEM}, {Namespaces::ATOM, ID_ELEM}
            # not mapped to unified model
          when {"", UPDATED_ELEM}, {Namespaces::ATOM, UPDATED_ELEM}
            raw = child.content.strip
            feed.updated = raw
            feed.updated_parsed = ::DateParse.parse(raw)
          when {"", LINK_ELEM}, {Namespaces::ATOM, LINK_ELEM}
            links << parse_link(child)
          when {"", AUTHOR_ELEM}, {Namespaces::ATOM, AUTHOR_ELEM}
            atom_authors << parse_person(child)
          when {"", CATEGORY_ELEM}, {Namespaces::ATOM, CATEGORY_ELEM}
            atom_cats << parse_category(child)
          when {"", GENERATOR_ELEM}, {Namespaces::ATOM, GENERATOR_ELEM}
            generator = parse_generator(child)
          when {"", ICON_ELEM}, {Namespaces::ATOM, ICON_ELEM}
            feed.image ||= Feeds::Image.new(url: child.content.strip)
          when {"", LOGO_ELEM}, {Namespaces::ATOM, LOGO_ELEM}
            feed.image = Feeds::Image.new(url: child.content.strip)
          when {"", RIGHTS_ELEM}, {Namespaces::ATOM, RIGHTS_ELEM}
            feed.copyright = text_content(child)
          when {"", ENTRY_ELEM}, {Namespaces::ATOM, ENTRY_ELEM}
            feed.items << parse_entry(child, fallback_authors: atom_authors)
          else
            parse_extension(child, prefix, Namespaces::ATOM_KNOWN, feed.extensions)
          end
        end

        finalize_feed_level_extensions(feed)
        finalize_atom_feed(feed, links, atom_authors, atom_cats, generator)
      end

      private def finalize_atom_feed(
        feed : Feeds::Feed,
        links : Array(Link),
        atom_authors : Array(Feeds::Person),
        atom_cats : Array(Category),
        generator : Generator?,
      )
        dc = feed.dublin_core_ext
        feed.link = find_link(links, LINK_ALTERNATE)
        feed.feed_link = find_link(links, LINK_SELF)
        feed.links = links.compact_map(&.href)
        feed.language ||= dc.try(&.language.first?)
        feed.copyright ||= dc.try(&.rights.first?)
        feed.updated_parsed ||= dc_date(dc)
        feed.updated ||= dc.try(&.date.first?)
        feed.description ||= itunes_field(feed, &.summary) || itunes_field(feed, &.subtitle)
        feed.generator = translate_generator(generator)
        feed.authors = resolve_atom_authors(atom_authors, dc, itunes_field(feed, &.author))

        native_cats = atom_cats.compact_map { |cat| cat.label || cat.term }.reject(&.empty?)
        feed.categories = translate_categories(native_cats, dc.try(&.subject) || [] of String, feed.itunes_ext)
      end

      # ameba:disable Metrics/CyclomaticComplexity
      private def parse_entry(node : XML::Node, fallback_authors : Array(Feeds::Person)) : Feeds::Item
        item = Feeds::Item.new
        links = [] of Link
        atom_authors = [] of Feeds::Person
        atom_cats = [] of Category

        node.children.each do |child|
          next unless child.element?
          prefix = canonical_prefix(child)
          case {prefix, child.name}
          when {"", TITLE_ELEM}, {Namespaces::ATOM, TITLE_ELEM}
            item.title = text_content(child)
          when {"", ID_ELEM}, {Namespaces::ATOM, ID_ELEM}
            item.guid = child.content.strip
          when {"", UPDATED_ELEM}, {Namespaces::ATOM, UPDATED_ELEM}
            raw = child.content.strip
            item.updated = raw
            item.updated_parsed = ::DateParse.parse(raw)
          when {"", PUBLISHED_ELEM}, {Namespaces::ATOM, PUBLISHED_ELEM}
            raw = child.content.strip
            item.published = raw
            item.published_parsed = ::DateParse.parse(raw)
          when {"", LINK_ELEM}, {Namespaces::ATOM, LINK_ELEM}
            links << parse_link(child)
          when {"", AUTHOR_ELEM}, {Namespaces::ATOM, AUTHOR_ELEM}
            atom_authors << parse_person(child)
          when {"", CATEGORY_ELEM}, {Namespaces::ATOM, CATEGORY_ELEM}
            atom_cats << parse_category(child)
          when {"", CONTENT_ELEM}, {Namespaces::ATOM, CONTENT_ELEM}
            item.content = parse_content(child).value
          when {"", SUMMARY_ELEM}, {Namespaces::ATOM, SUMMARY_ELEM}
            item.description = text_content(child)
          when {"", RIGHTS_ELEM}, {Namespaces::ATOM, RIGHTS_ELEM}
            # not mapped
          else
            parse_extension(child, prefix, Namespaces::ATOM_KNOWN, item.extensions)
          end
        end

        finalize_item_level_extensions(item)
        finalize_atom_entry(item, links, atom_authors.empty? ? fallback_authors : atom_authors, atom_cats)
        item
      end

      private def finalize_atom_entry(
        item : Feeds::Item,
        links : Array(Link),
        authors : Array(Feeds::Person),
        atom_cats : Array(Category),
      )
        dc = item.dublin_core_ext
        item.title ||= dc.try(&.title.first?)
        item.description ||= dc.try(&.description.first?) || item.itunes_ext.try(&.summary)
        item.updated_parsed ||= dc_date(dc)
        item.updated ||= dc.try(&.date.first?)
        all_links = [] of String
        enclosures = [] of Feeds::Enclosure
        links.each do |link|
          link.href.try { |href| all_links << href }
          if link.rel == LINK_ENCLOSURE
            enclosures << Feeds::Enclosure.new(url: link.href, length: link.length, type: link.type)
          end
        end
        item.link = find_link(links, LINK_ALTERNATE)
        item.links = all_links
        item.enclosures = enclosures
        item.authors = resolve_atom_authors(authors, dc, item.itunes_ext.try(&.author))

        native_cats = atom_cats.compact_map { |cat| cat.label || cat.term }.reject(&.empty?)
        item.categories = translate_categories(native_cats, dc.try(&.subject) || [] of String, item.itunes_ext)
      end

      private def parse_link(node : XML::Node) : Link
        Link.new(
          href: node[HREF_ATTR]?,
          rel: node[REL_ATTR]?,
          type: node[TYPE_ATTR]?,
          hreflang: node[HREFLANG_ATTR]?,
          title: node[TITLE_ATTR]?,
          length: node[LENGTH_ATTR]?,
        )
      end

      private def parse_person(node : XML::Node) : Feeds::Person
        person = Feeds::Person.new
        node.children.each do |child|
          next unless child.element?
          case child.name
          when NAME_ELEM  then person.name = child.content.strip
          when EMAIL_ELEM then person.email = child.content.strip
          when URI_ELEM   then person.uri = child.content.strip
          end
        end
        person
      end

      private def parse_category(node : XML::Node) : Category
        Category.new(term: node[TERM_ATTR]?, scheme: node[SCHEME_ATTR]?, label: node[LABEL_ATTR]?)
      end

      private def parse_generator(node : XML::Node) : Generator
        Generator.new(value: node.content.strip, uri: node[URI_ATTR]?, version: node[VERSION_ATTR]?)
      end

      private def parse_content(node : XML::Node) : Content
        type = node[TYPE_ATTR]?
        value = type == XHTML_TYPE ? xhtml_content(node) : node.content.strip
        Content.new(value: value, type: type, src: node[SRC_ATTR]?)
      end

      private def translate_generator(gen : Generator?) : String?
        return unless gen
        value = gen.value
        return if value.nil? || value.empty?
        gen.version ? "#{value}#{GENERATOR_VERSION_SEP}#{gen.version}" : value
      end

      private def find_link(links : Array(Link), rel : String) : String?
        links.find { |link| link.rel == rel }.try(&.href) ||
          (rel == LINK_ALTERNATE ? links.find { |link| link.rel.nil? }.try(&.href) : nil)
      end

      private def resolve_atom_authors(
        atom_persons : Array(Feeds::Person),
        dc : Feeds::DublinCoreExtension?,
        itunes_author : String?,
      ) : Array(Feeds::Person)
        return atom_persons unless atom_persons.empty?
        dc_source = dc.try(&.creator.first?) || dc.try(&.author.first?)
        return [Feeds::Person.new(name: dc_source)] if dc_source
        if itunes_author && !itunes_author.empty?
          return [Feeds::Person.new(name: itunes_author)]
        end
        [] of Feeds::Person
      end

      private def text_content(node : XML::Node) : String
        node[TYPE_ATTR]? == XHTML_TYPE ? xhtml_content(node) : node.content.strip
      end

      private def xhtml_content(node : XML::Node) : String
        node.children.each do |child|
          if child.element? && child.name == DIV_ELEM
            return String.build { |str| child.children.each { |xml_child| str << xml_child.to_xml } }.strip
          end
        end
        node.content.strip
      end

      private def extract_xml_lang(node : XML::Node) : String?
        node.attributes.each do |attr|
          return attr.content if attr.name == LANG_ATTR
        end
        nil
      end
    end
  end
end
