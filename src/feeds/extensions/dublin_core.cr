module Feeds
  # Dublin Core metadata extension (http://purl.org/dc/elements/1.1/)
  #
  # All fields are arrays (the DC specification allows each element to repeat)
  class DublinCoreExtension
    property title : Array(String) = [] of String
    property creator : Array(String) = [] of String
    property author : Array(String) = [] of String
    property subject : Array(String) = [] of String
    property description : Array(String) = [] of String
    property publisher : Array(String) = [] of String
    property contributor : Array(String) = [] of String
    property date : Array(String) = [] of String
    property type : Array(String) = [] of String
    property format : Array(String) = [] of String
    property identifier : Array(String) = [] of String
    property source : Array(String) = [] of String
    property language : Array(String) = [] of String
    property relation : Array(String) = [] of String
    property coverage : Array(String) = [] of String
    property rights : Array(String) = [] of String
  end
end
