module Rux
  module Lex
    class State
      def self.parse(state_str, transition_strs, inputs)
        is_terminal = state_str.end_with?('*')
        state_name = "tRUX_#{state_str.chomp('*').upcase}".to_sym

        transitions = transition_strs.each_with_object([]).with_index do |(ts, ret), idx|
          ret << Transition.parse(ts, inputs[idx]) if ts
        end

        new(state_name, is_terminal, transitions)
      end

      attr_reader :name, :is_terminal, :transitions

      alias_method :terminal?, :is_terminal

      def initialize(name, is_terminal, transitions)
        @name = name
        @is_terminal = is_terminal
        @transitions = transitions
        @cache = {}
      end

      def [](chr)
        @cache[chr] ||= transitions.find do |trans|
          trans.matches?(chr)
        end
      end
    end
  end
end
