module Rux
  module AST
    class RootNode
      attr_reader :list

      def initialize(list)
        @list = list
      end

      def accept(visitor)
        visitor.visit_root(self)
      end

      def children
        @children ||= [list]
      end
    end
  end
end
