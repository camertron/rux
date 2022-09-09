module Rux
  module AST
    class ListNode
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def accept(visitor)
        visitor.visit_list(self)
      end

      def type
        :list
      end
    end
  end
end
