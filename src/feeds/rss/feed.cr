module Feeds
  module RSS
    class Category
      property domain : String?
      property value : String?

      def initialize(@domain = nil, @value = nil)
      end
    end

    class GUID
      property value : String?
      property is_permalink : String?

      def initialize(@value = nil, @is_permalink = nil)
      end
    end
  end
end
