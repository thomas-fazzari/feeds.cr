module Feeds
  class UnknownFormatError < Exception
    def initialize(msg : String = "Unknown or unsupported feed format")
      super(msg)
    end
  end

  class ParseError < Exception
    def initialize(msg : String = "Failed to parse feed")
      super(msg)
    end
  end

  class Detector
    def self.detect(content : String) : FeedType
      stripped = content.lchop(UTF8_BOM).lstrip
      stripped.starts_with?('{') ? FeedType::JSON : detect_xml(stripped)
    end

    private def self.detect_xml(content : String) : FeedType
      root = XML.parse(content).root
      raise UnknownFormatError.new unless root
      case root.name
      when Namespaces::RSS then FeedType::RSS
      when RDF_ROOT        then FeedType::RSS
      when ATOM_ROOT       then FeedType::Atom
      else                      raise UnknownFormatError.new
      end
    rescue XML::Error
      raise UnknownFormatError.new
    end
  end
end
