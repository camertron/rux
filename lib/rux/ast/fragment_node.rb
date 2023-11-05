module Rux
  module AST
    class FragmentNode
      attr_reader :children

      def initialize
        @children = []
      end

      def accept(visitor)
        visitor.visit_fragment(self)
      end
    end
  end
end
