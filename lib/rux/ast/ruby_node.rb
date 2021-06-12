module Rux
  module AST
    class RubyNode
      attr_reader :tokens

      def initialize(tokens)
        @tokens = tokens
      end

      def accept(visitor, &block)
        visitor.visit_ruby(self, &block)
      end
    end
  end
end
