module Rux
  module AST
    class AttrsNode
      include Enumerable

      attr_reader :attrs, :pos

      def initialize(attrs, pos)
        @attrs = attrs
        @pos = pos
      end

      def each(&block)
        attrs.each(&block)
      end

      def empty?
        attrs.empty?
      end
    end
  end
end
