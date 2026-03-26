module Feeds
  class Person
    property name : String?
    property email : String?
    property uri : String?

    def initialize(@name = nil, @email = nil, @uri = nil)
    end
  end

  # Width and height are raw strings to preserve the original feed value
  class Image
    property url : String?
    property title : String?
    property link : String?
    property width : String?
    property height : String?

    def initialize(@url = nil, @title = nil, @link = nil, @width = nil, @height = nil)
    end
  end

  # Represents an enclosure attachment (e.g. a podcast audio file)
  #
  # Length is the file size in bytes, as a string to preserve the raw feed value
  class Enclosure
    property url : String?
    property length : String?
    property type : String?

    def initialize(@url = nil, @length = nil, @type = nil)
    end
  end

  class Item
    property title : String?
    property description : String?
    property content : String?
    property link : String?
    property links : Array(String) = [] of String
    property updated : String? # Raw date string from feed
    property updated_parsed : Time?
    property published : String? # Raw date string from feed
    property published_parsed : Time?
    property authors : Array(Person) = [] of Person
    property guid : String?
    property custom : Hash(String, String) = {} of String => String # Contains unrecognized elements captured during RSS parsing
    property image : Image?
    property categories : Array(String) = [] of String
    property enclosures : Array(Enclosure) = [] of Enclosure
    property extensions : Hash(String, Hash(String, Array(Extension))) = {} of String => Hash(String, Array(Extension))
    property dublin_core_ext : DublinCoreExtension?
    property itunes_ext : ITunesItemExtension?

    def extension_values(prefix : String, name : String) : Array(String)
      extensions[prefix]?.try { |namespace| namespace[name]?.try(&.map(&.value)) } || [] of String
    end
  end

  class Feed
    property title : String?
    property description : String?
    property link : String?
    property feed_link : String? # URL of the feed itself, distinct from link (site URL)
    property links : Array(String) = [] of String
    property updated : String?
    property updated_parsed : Time?
    property published : String?
    property published_parsed : Time?
    property authors : Array(Person) = [] of Person
    property language : String?
    property image : Image?
    property copyright : String?
    property generator : String?
    property categories : Array(String) = [] of String
    property items : Array(Item) = [] of Item
    property extensions : Hash(String, Hash(String, Array(Extension))) = {} of String => Hash(String, Array(Extension))
    property dublin_core_ext : DublinCoreExtension?
    property itunes_ext : ITunesFeedExtension?
    property feed_type : FeedType
    property feed_version : String = ""

    def initialize(@feed_type : FeedType)
    end

    def extension_values(prefix : String, name : String) : Array(String)
      extensions[prefix]?.try { |namespace| namespace[name]?.try(&.map(&.value)) } || [] of String
    end
  end
end
