module Rux
  module AST
    class RubyNode
      attr_reader :code

      def initialize(code)
        @code = code
      end

      def accept(visitor)
        visitor.visit_ruby(self)
      end
    end
  end
end
