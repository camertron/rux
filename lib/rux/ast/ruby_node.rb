module Rux
  module AST
    class RubyNode
      attr_reader :code, :pos

      def initialize(code, pos)
        @code = code
        @pos = pos
      end

      def accept(visitor)
        visitor.visit_ruby(self)
      end
    end
  end
end
