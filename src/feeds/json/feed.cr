require "json"

module Feeds
  module JSON
    class Author
      include ::JSON::Serializable

      property name : String? = nil
      property url : String? = nil
      property avatar : String? = nil
    end

    class Attachment
      include ::JSON::Serializable

      property url : String? = nil
      property mime_type : String? = nil
      property title : String? = nil
      property size_in_bytes : Int64? = nil
      property duration_in_seconds : Int64? = nil
    end

    class Item
      include ::JSON::Serializable

      property id : ::JSON::Any? = nil
      property url : String? = nil
      property external_url : String? = nil
      property title : String? = nil
      property content_html : String? = nil
      property content_text : String? = nil
      property summary : String? = nil
      property image : String? = nil
      property banner_image : String? = nil
      property date_published : String? = nil
      property date_modified : String? = nil
      property author : Author? = nil
      property authors : Array(Author)? = nil
      property language : String? = nil
      property tags : Array(String)? = nil
      property attachments : Array(Attachment)? = nil

      def string_id : String?
        id.try(&.to_s.presence)
      end
    end

    class Feed
      include ::JSON::Serializable

      property version : String? = nil
      property title : String? = nil
      property home_page_url : String? = nil
      property feed_url : String? = nil
      property description : String? = nil
      property user_comment : String? = nil
      property next_url : String? = nil
      property icon : String? = nil
      property favicon : String? = nil
      property author : Author? = nil
      property authors : Array(Author)? = nil
      property language : String? = nil
      property expired : Bool? = nil
      property items : Array(Item) = [] of Item
    end
  end
end
