module Rux
  module AST
    class StringNode
      attr_reader :str, :pos

      def initialize(str, pos)
        @str = str
        @pos = pos
      end

      def accept(visitor, &block)
        visitor.visit_string(self, &block)
      end
    end
  end
end
