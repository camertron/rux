module Rux
  module AST
    class TextNode
      attr_reader :text

      def initialize(text)
        @text = text
      end

      def to_ruby
        "\"#{text}\".html_safe"
      end

      def type
        :text
      end
    end
  end
end
