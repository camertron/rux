module Rux
  module AST
    class TagNode
      attr_reader :name, :attrs, :children

      def initialize(name, attrs)
        @name = name
        @attrs = attrs
        @children = []
      end

      def accept(visitor)
        visitor.visit_tag(self)
      end

      def type
        :tag
      end
    end
  end
end
