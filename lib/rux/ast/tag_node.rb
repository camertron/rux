module Rux
  module AST
    class TagNode
      attr_reader :name, :attrs, :self_closing, :pos, :children

      def initialize(name, attrs, self_closing, pos)
        @name = name
        @attrs = attrs
        @self_closing = self_closing
        @pos = pos
        @children = []
      end

      alias self_closing? self_closing

      def with_attrs(new_attrs)
        self.class.new(name, attrs.with_attrs(new_attrs), self_closing, pos).tap do |new_node|
          new_node.instance_variable_set(:@children, children)
        end
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
