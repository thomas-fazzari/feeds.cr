module Feeds
  module Atom
    class Link
      property href : String?
      property rel : String?
      property type : String?
      property hreflang : String?
      property title : String?
      property length : String?

      def initialize(@href = nil, @rel = nil, @type = nil, @hreflang = nil, @title = nil, @length = nil)
      end
    end

    class Category
      property term : String?
      property scheme : String?
      property label : String?

      def initialize(@term = nil, @scheme = nil, @label = nil)
      end
    end

    class Generator
      property value : String?
      property uri : String?
      property version : String?

      def initialize(@value = nil, @uri = nil, @version = nil)
      end
    end

    class Content
      property value : String?
      property type : String?
      property src : String?

      def initialize(@value = nil, @type = nil, @src = nil)
      end
    end
  end
end
