module Rux
  module AST
    class StringNode
      attr_reader :str, :quote_type, :pos

      def initialize(str, quote_type, pos)
        @str = str
        @quote_type = quote_type
        @pos = pos
      end

      def accept(visitor)
        visitor.visit_string(self)
      end
    end
  end
end
