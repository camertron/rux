require 'csv'

module Rux
  class StateTable
    attr_reader :path, :start_state, :state_prefix

    def initialize(path, start_state, state_prefix)
      @path = path
      @start_state = :"#{state_prefix}#{start_state}"
      @state_prefix = state_prefix
    end

    def [](state)
      state_table[state]
    end

    def include?(name)
      state_table.include?(name)
    end

    private

    def state_table
      @state_table ||= {}.tap do |table|
        state_table_data = CSV.read(path)
        input_patterns = state_table_data[0][1..-1]

        inputs = input_patterns.map do |pattern|
          parse_pattern(pattern)
        end

        state_table_data[1..-1].each do |row|
          next unless row[0]  # allows blank lines in csv

          state = Lex::State.parse(row[0], row[1..-1], inputs, state_prefix)
          table[state.name] = state
        end
      end
    end

    def parse_pattern(pattern)
      if pattern == '(space)'
        Lex::CharsetPattern.new([' ', "\r", "\n"])
      elsif pattern == '(default)'
        Lex::DefaultPattern.new
      elsif pattern == '(eof)'
        Lex::EofPattern.new
      elsif pattern.start_with?('[^')
        Lex::NegatedCharsetPattern.parse(pattern[2..-2])
      else
        Lex::CharsetPattern.parse(pattern[1..-2])
      end
    end
  end
end
