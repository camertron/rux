module Rux
  module AST
    class FragmentNode
      attr_reader :children, :pos

      def initialize(pos)
        @children = []
        @pos = pos
      end

      def accept(visitor)
        visitor.visit_fragment(self)
      end
    end
  end
end
