module Rux
  module AST
    class ListNode
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def to_ruby
        children.map(&:to_ruby).join
      end

      def type
        :list
      end
    end
  end
end
