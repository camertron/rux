require 'cgi'

module Rux
  module AST
    class TextNode
      attr_reader :text, :pos

      def initialize(text, pos)
        @text = text
        @pos = pos
      end

      def accept(visitor, &block)
        visitor.visit_text(self, &block)
      end
    end
  end
end
