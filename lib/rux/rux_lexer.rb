module Rux
  class RuxLexer
    class << self
      def state_table
        @state_table ||= StateTable.new(state_table_path, :tRUX_START)
      end

      private

      # See: https://docs.google.com/spreadsheets/d/11ikKuySIKoaj-kFIfhlzebUwH31cRt_1flGjWfk7RMg
      def state_table_path
        @state_table_path ||=
          ::File.expand_path(::File.join('.', 'lex', 'states.csv'), __dir__)
      end
    end


    def initialize(source_buffer, init_pos)
      @state_machine = StateMachine.new(
        self.class.state_table, source_buffer, init_pos
      )

      @eof = false
      @generator = to_enum(:each_token)
    end

    def advance
      @generator.next
    rescue StopIteration
      [nil, ['$eof']]
    end

    def reset_to(pos)
      @state_machine.reset_to(pos)
      @eof = false
    end

    def next_lexer(pos)
      RubyLexer.new(@state_machine.source_buffer, pos)
    end

    private

    def each_token
      tag_stack = []
      @eof = false

      loop do
        token = @state_machine.advance
        state, (text, pos) = token
        break unless state

        if ruby_code?(state)
          @eof = true

          # @eof is set to false by reset_to above, which is called after
          # popping the previous lexer off the lexer stack (see lexer.rb)
          while @eof
            yield [nil, ['$eof', pos]]
          end

          next
        end

        yield token

        case state
          when :tRUX_TAG_OPEN, :tRUX_TAG_SELF_CLOSING
            tag_stack.push(text)
          when :tRUX_TAG_CLOSE
            tag_stack.pop
          when :tRUX_TAG_CLOSE_END
            break if tag_stack.empty?
          when :tRUX_TAG_SELF_CLOSING_END
            tag_stack.pop
            break if tag_stack.empty?
        end
      end
    end

    # Ruby code can only exist in two places: attribute values and inside tag
    # bodies. Eventually I'd like to also allow passing a Ruby hash to
    # dynamically specify attributes, but we're not there yet.
    def ruby_code?(state)
      state == :tRUX_ATTRIBUTE_VALUE_RUBY_CODE ||
        state == :tRUX_LITERAL_RUBY_CODE
    end
  end
end
