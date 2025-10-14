module Rux
  module AST
    class RootNode
      attr_reader :list, :source_buffer

      def initialize(list, source_buffer)
        @list = list
        @source_buffer = source_buffer
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
