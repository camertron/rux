module Rux
  module AST
    class AttrsNode
      include Enumerable

      attr_reader :attrs, :pos

      def initialize(attrs, pos)
        @attrs = attrs
        @pos = pos
      end

      def with_attrs(new_attrs)
        self.class.new([*attrs, *new_attrs], pos)
      end

      def accept(visitor)
        visitor.visit_attrs(self)
      end

      def each(&block)
        attrs.each(&block)
      end

      def empty?
        attrs.empty?
      end

      def get(name)
        find { |attr| attr.name == name }
      end
    end
  end
end
