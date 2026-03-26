module Feeds
  def self.parse(content : String) : Feed
    Parser.new.parse(content)
  end

  class Parser
    def parse(content : String) : Feed
      case Detector.detect(content)
      in FeedType::RSS  then RSS::Parser.new.parse(content)
      in FeedType::Atom then Atom::Parser.new.parse(content)
      in FeedType::JSON then JSON::Parser.new.parse(content)
      end
    end
  end
end
