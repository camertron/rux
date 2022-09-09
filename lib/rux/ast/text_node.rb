require 'cgi'

module Rux
  module AST
    class TextNode
      attr_reader :text

      def initialize(text)
        @text = text
      end

      def accept(visitor)
        visitor.visit_text(self)
      end

      def type
        :text
      end
    end
  end
end
