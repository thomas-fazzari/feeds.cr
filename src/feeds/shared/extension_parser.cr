module Feeds
  module Shared
    module ExtensionParser
      private def find_root(doc : XML::Node) : XML::Node
        doc.children.find(&.element?) || raise ParseError.new(NO_ROOT_ELEMENT_MSG)
      end

      private def parse_extension(node : XML::Node, prefix : String, inline_prefixes, extensions : Hash(String, Hash(String, Array(Feeds::Extension))))
        return if inline_prefixes.includes?(prefix)
        extensions[prefix] ||= {} of String => Array(Feeds::Extension)
        extensions[prefix][node.name] ||= [] of Feeds::Extension
        extensions[prefix][node.name] << build_extension(node)
      end

      private def finalize_feed_level_extensions(obj)
        if itunes = obj.extensions[Namespaces::ITUNES]?
          obj.itunes_ext = build_itunes_feed_ext(itunes)
        end
        if dc = obj.extensions[Namespaces::DC]?
          obj.dublin_core_ext = build_dc_ext(dc)
        end
      end

      private def finalize_item_level_extensions(obj)
        if itunes = obj.extensions[Namespaces::ITUNES]?
          obj.itunes_ext = build_itunes_item_ext(itunes)
        end
        if dc = obj.extensions[Namespaces::DC]?
          obj.dublin_core_ext = build_dc_ext(dc)
        end
      end

      private def canonical_prefix(node : XML::Node) : String
        ns = node.namespace
        return "" unless ns
        ns_uri = ns.href || ""
        return "" if ns_uri.empty?
        Namespaces.canonical_prefix(ns_uri, ns.prefix || "")
      end

      private def build_extension(node : XML::Node) : Feeds::Extension
        ext = Feeds::Extension.new
        ext.name = node.name
        ext.value = node.content.strip
        node.attributes.each do |attr|
          ext.attrs[attr.name] = attr.content
        end
        node.children.each do |child|
          next unless child.element?
          ext.children[child.name] ||= [] of Feeds::Extension
          ext.children[child.name] << build_extension(child)
        end
        ext
      end

      # Returns the text value of the first occurrence of an iTunes element, or nil if absent
      private def itunes_val(itunes : Hash(String, Array(Feeds::Extension)), key : String) : String?
        itunes[key]?.try(&.first?.try(&.value))
      end

      # Returns all text values for a Dublin Core element as an array, or [] if absent
      private def dc_vals(dc : Hash(String, Array(Feeds::Extension)), key : String) : Array(String)
        dc[key]?.try(&.map(&.value)) || [] of String
      end

      private def build_itunes_feed_ext(itunes : Hash(String, Array(Feeds::Extension))) : Feeds::ITunesFeedExtension
        Feeds::ITunesFeedExtension.new.tap do |ext|
          ext.author = itunes_val(itunes, ITunes::AUTHOR)
          ext.block = itunes_val(itunes, ITunes::BLOCK)
          ext.explicit = itunes_val(itunes, ITunes::EXPLICIT)
          ext.keywords = itunes_val(itunes, ITunes::KEYWORDS)
          ext.subtitle = itunes_val(itunes, ITunes::SUBTITLE)
          ext.summary = itunes_val(itunes, ITunes::SUMMARY)
          ext.complete = itunes_val(itunes, ITunes::COMPLETE)
          ext.new_feed_url = itunes_val(itunes, ITunes::NEW_FEED_URL)
          ext.type = itunes_val(itunes, ITunes::TYPE)
          ext.image = itunes[ITunes::IMAGE]?.try(&.first?.try(&.attrs[HREF_ATTR]?))
          if owner_ext = itunes[ITunes::OWNER]?.try(&.first?)
            owner = Feeds::ITunesOwner.new
            owner.name = owner_ext.children[NAME_ELEM]?.try(&.first?.try(&.value))
            owner.email = owner_ext.children[EMAIL_ELEM]?.try(&.first?.try(&.value))
            ext.owner = owner
          end
          itunes[ITunes::CATEGORY]?.try(&.each do |cat_ext|
            cat = Feeds::ITunesCategory.new
            cat.text = cat_ext.attrs[TEXT_ATTR]? || ""
            cat_ext.children[ITunes::CATEGORY]?.try(&.first?).try do |sub|
              sub_cat = Feeds::ITunesCategory.new
              sub_cat.text = sub.attrs[TEXT_ATTR]? || ""
              cat.subcategory = sub_cat
            end
            ext.categories << cat
          end)
        end
      end

      private def build_itunes_item_ext(itunes : Hash(String, Array(Feeds::Extension))) : Feeds::ITunesItemExtension
        Feeds::ITunesItemExtension.new.tap do |ext|
          ext.author = itunes_val(itunes, ITunes::AUTHOR)
          ext.block = itunes_val(itunes, ITunes::BLOCK)
          ext.duration = itunes_val(itunes, ITunes::DURATION)
          ext.explicit = itunes_val(itunes, ITunes::EXPLICIT)
          ext.keywords = itunes_val(itunes, ITunes::KEYWORDS)
          ext.subtitle = itunes_val(itunes, ITunes::SUBTITLE)
          ext.summary = itunes_val(itunes, ITunes::SUMMARY)
          ext.closed_captioned = itunes_val(itunes, ITunes::CLOSED_CAPTIONED)
          ext.episode = itunes_val(itunes, ITunes::EPISODE)
          ext.season = itunes_val(itunes, ITunes::SEASON)
          ext.order = itunes_val(itunes, ITunes::ORDER)
          ext.episode_type = itunes_val(itunes, ITunes::EPISODE_TYPE)
          ext.image = itunes[ITunes::IMAGE]?.try(&.first?.try(&.attrs[HREF_ATTR]?))
        end
      end

      private def build_dc_ext(dc : Hash(String, Array(Feeds::Extension))) : Feeds::DublinCoreExtension
        Feeds::DublinCoreExtension.new.tap do |ext|
          ext.title = dc_vals(dc, DublinCore::TITLE)
          ext.creator = dc_vals(dc, DublinCore::CREATOR)
          ext.author = dc_vals(dc, DublinCore::AUTHOR)
          ext.subject = dc_vals(dc, DublinCore::SUBJECT)
          ext.description = dc_vals(dc, DublinCore::DESCRIPTION)
          ext.publisher = dc_vals(dc, DublinCore::PUBLISHER)
          ext.contributor = dc_vals(dc, DublinCore::CONTRIBUTOR)
          ext.date = dc_vals(dc, DublinCore::DATE)
          ext.type = dc_vals(dc, DublinCore::TYPE)
          ext.format = dc_vals(dc, DublinCore::FORMAT)
          ext.identifier = dc_vals(dc, DublinCore::IDENTIFIER)
          ext.source = dc_vals(dc, DublinCore::SOURCE)
          ext.language = dc_vals(dc, DublinCore::LANGUAGE)
          ext.relation = dc_vals(dc, DublinCore::RELATION)
          ext.coverage = dc_vals(dc, DublinCore::COVERAGE)
          ext.rights = dc_vals(dc, DublinCore::RIGHTS)
        end
      end

      private def split_keywords(raw : String?) : Array(String)
        raw.try { |keywords| keywords.split(',').map(&.strip).reject(&.empty?) } || [] of String
      end

      private def dc_date(dc : Feeds::DublinCoreExtension?) : Time?
        dc.try(&.date.first?).try { |date| ::DateParse.parse(date) }
      end

      private def itunes_field(feed, &block : Feeds::ITunesFeedExtension -> String?) : String?
        feed.itunes_ext.try { |ext| block.call(ext) }
      end

      private def translate_categories(
        native_cats : Array(String),
        dc_subjects : Array(String),
        itunes : Feeds::ITunesFeedExtension?,
      ) : Array(String)
        cats = native_cats + dc_subjects
        if ext = itunes
          cats.concat(split_keywords(ext.keywords))
          cats.concat(ext.categories.map(&.text))
        end
        cats.uniq
      end

      private def translate_categories(
        native_cats : Array(String),
        dc_subjects : Array(String),
        itunes : Feeds::ITunesItemExtension?,
      ) : Array(String)
        cats = native_cats + dc_subjects
        cats.concat(split_keywords(itunes.try(&.keywords)))
        cats.uniq
      end
    end
  end
end
