module Rux
  module AST
    class TagNode
      attr_reader :name, :attrs, :pos, :children

      def initialize(name, attrs, pos)
        @name = name
        @attrs = attrs
        @pos = pos
        @children = []
      end

      def accept(visitor, &block)
        visitor.visit_tag(self, &block)
      end
    end
  end
end
