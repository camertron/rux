module Rux
  module AST
    class AttrNode
      attr_reader :name, :value, :name_pos
      attr_accessor :tag_node

      def initialize(name, value, name_pos)
        @name = name
        @value = value
        @name_pos = name_pos
      end

      def accept(visitor)
        visitor.visit_attr(self)
      end

      def ruby_code?
        false
      end
    end
  end
end
