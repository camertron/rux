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

      def component?
        name.start_with?(/[A-Z]/)
      end
    end
  end
end
