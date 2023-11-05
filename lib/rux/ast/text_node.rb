require 'cgi'

module Rux
  module AST
    class TextNode
      attr_reader :text

      def initialize(text, pos)
        @text = text
        @pos = pos
      end

      def accept(visitor)
        visitor.visit_text(self)
      end
    end
  end
end
