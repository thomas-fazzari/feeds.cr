module Feeds
  module JSON
    class Parser
      include Shared::ExtensionParser

      def parse(content : String) : Feeds::Feed
        json_feed = JSON::Feed.from_json(content)
        build_feed(json_feed)
      rescue ex : ::JSON::ParseException
        raise ParseError.new("#{PARSE_ERROR_PREFIX}#{ex.message}")
      end

      private def build_feed(json : JSON::Feed) : Feeds::Feed
        feed = Feeds::Feed.new(FeedType::JSON)
        feed.feed_version = normalize_version(json.version)
        feed.title = json.title
        feed.description = json.description
        feed.link = json.home_page_url
        feed.feed_link = json.feed_url
        feed.links = compact_links(json.home_page_url, json.feed_url)
        feed.language = json.language
        feed.image = json.icon.try { |icon_url| Feeds::Image.new(url: icon_url) }
        feed.authors = translate_authors(json.authors, json.author)
        feed.published = json.items.first?.try(&.date_published)
        feed.published_parsed = feed.published.try { |date| ::DateParse.parse(date) }
        feed.updated = json.items.first?.try(&.date_modified)
        feed.updated_parsed = feed.updated.try { |date| ::DateParse.parse(date) }
        feed.items = json.items.map { |item| build_item(item) }
        feed
      end

      private def build_item(json : JSON::Item) : Feeds::Item
        item = Feeds::Item.new
        item.guid = json.string_id
        item.title = json.title
        item.description = json.summary
        item.content = json.content_html || json.content_text
        item.link = json.url
        item.links = compact_links(json.url, json.external_url)
        item.image = translate_item_image(json)
        item.published = json.date_published
        item.published_parsed = item.published.try { |date| ::DateParse.parse(date) }
        item.updated = json.date_modified
        item.updated_parsed = item.updated.try { |date| ::DateParse.parse(date) }
        item.authors = translate_authors(json.authors, json.author)
        json.tags.try { |tags| item.categories = tags }
        json.attachments.try { |atts| item.enclosures = translate_attachments(atts) }
        item
      end

      private def translate_authors(authors : Array(JSON::Author)?, singular : JSON::Author?) : Array(Feeds::Person)
        if list = authors
          return list.map { |author| Feeds::Person.new(name: author.name, uri: author.url) } unless list.empty?
        end
        if author = singular
          return [Feeds::Person.new(name: author.name, uri: author.url)]
        end
        [] of Feeds::Person
      end

      private def translate_item_image(item : JSON::Item) : Feeds::Image?
        url = item.image || item.banner_image
        url.try { |image_url| Feeds::Image.new(url: image_url) }
      end

      private def translate_attachments(attachments : Array(JSON::Attachment)) : Array(Feeds::Enclosure)
        attachments.map do |att|
          Feeds::Enclosure.new(
            url: att.url,
            type: att.mime_type,
            length: att.duration_in_seconds.try(&.to_s),
          )
        end
      end

      private def compact_links(*urls : String?) : Array(String)
        result = [] of String
        urls.each { |link_url| result << link_url if link_url && !link_url.empty? }
        result
      end

      private def normalize_version(raw : String?) : String
        case raw
        when nil                             then ""
        when .includes?(FEED_VERSION_11_URI) then FEED_VERSION_11
        when .includes?(FEED_VERSION_1_URI)  then FEED_VERSION_10
        else                                      raw
        end
      end
    end
  end
end
