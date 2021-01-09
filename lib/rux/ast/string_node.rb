module Rux
  module AST
    class StringNode
      attr_reader :str

      def initialize(str)
        @str = str
      end

      def accept(visitor)
        visitor.visit_string(self)
      end
    end
  end
end
