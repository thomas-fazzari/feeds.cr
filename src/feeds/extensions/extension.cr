module Feeds
  # Represents a single XML element from an unknown or unregistered namespace
  #
  # The tree structure mirrors the XML:
  #  - attrs holds element attributes
  #  - children holds nested elements keyed by local name
  class Extension
    property name : String = ""
    property value : String = ""
    property attrs : Hash(String, String) = {} of String => String
    property children : Hash(String, Array(Extension)) = {} of String => Array(Extension)
  end
end
