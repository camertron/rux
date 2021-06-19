module Rux
  module AST
    class AttrNode
      attr_reader :name, :value, :name_pos

      def initialize(name, value, name_pos)
        @name = name
        @value = value
        @name_pos = name_pos
      end
    end
  end
end
