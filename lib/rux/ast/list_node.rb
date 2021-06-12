module Rux
  module AST
    class ListNode
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def accept(visitor, &block)
        visitor.visit_list(self, &block)
      end
    end
  end
end
