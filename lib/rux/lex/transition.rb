module Rux
  module Lex
    class Transition
      attr_reader :input, :to_state, :advance_count

      def self.parse(str, input, prefix)
        to_state, advance_count = str.match(/\A(\w+)\[?(-?\d+)?\]?/).captures
        new(input, :"#{prefix}#{to_state.upcase}", (advance_count || 1).to_i)
      end

      def initialize(input, to_state, advance_count)
        @input = input
        @to_state = to_state
        @advance_count = advance_count
      end

      def matches?(chr)
        input.matches?(chr)
      end
    end
  end
end
