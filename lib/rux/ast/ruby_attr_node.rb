module Rux
  module AST
    class RubyAttrNode
      attr_reader :ruby_node
      attr_accessor :tag_node

      def initialize(ruby_node)
        @ruby_node = ruby_node
      end

      def code
        ruby_node.code
      end

      def accept(visitor)
        visitor.visit_attr(self)
      end

      def ruby_code?
        true
      end

      def name
        nil
      end
    end
  end
end
