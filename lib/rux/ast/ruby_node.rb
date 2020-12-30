module Rux
  module AST
    class RubyNode
      attr_reader :code

      def initialize(code)
        @code = code
      end

      def to_ruby
        code
      end

      def type
        :ruby
      end
    end
  end
end
