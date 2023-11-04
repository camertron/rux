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

      def slot_component?
        name.start_with?("With")
      end

      def slot_method
        @slot_method ||= name.gsub(/(?<!^)([A-Z])/) { |x| "_#{x}" }.downcase
      end
    end
  end
end
