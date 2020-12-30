module Rux
  module AST
    class StringNode
      attr_reader :str

      def initialize(str)
        @str = str
      end

      def to_ruby
        str
      end

      def type
        :string
      end
    end
  end
end
