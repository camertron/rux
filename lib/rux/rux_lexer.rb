require 'csv'

module Rux
  class RuxLexer
    class << self
      # See: https://docs.google.com/spreadsheets/d/11ikKuySIKoaj-kFIfhlzebUwH31cRt_1flGjWfk7RMg
      def state_table
        @state_table ||= {}.tap do |table|
          state_table_data = CSV.read(state_table_path)
          input_patterns = state_table_data[0][1..-1]

          inputs = input_patterns.map do |pattern|
            parse_pattern(pattern)
          end

          state_table_data[1..-1].each do |row|
            next unless row[0]  # allows blank lines in csv

            state = Lex::State.parse(row[0], row[1..-1], inputs)
            table[state.name] = state
          end
        end
      end

      def state_table_path
        @state_table_path ||=
          ::File.expand_path(::File.join('.', 'lex', 'states.csv'), __dir__)
      end

      def parse_pattern(pattern)
        if pattern == "(space)"
          Lex::CharsetPattern.new([' ', "\r", "\n"])
        elsif pattern == "(default)"
          Lex::DefaultPattern.new
        elsif pattern.start_with?('[^')
          Lex::NegatedCharsetPattern.parse(pattern[2..-2])
        else
          Lex::CharsetPattern.parse(pattern[1..-2])
        end
      end
    end


    def initialize(source_buffer, init_pos)
      @p = init_pos
      @source_buffer = source_buffer
      @source_pts = @source_buffer.source.unpack('U*')
      @generator = to_enum(:each_token)
    end

    def advance
      @generator.next
    end

    def reset_to(pos)
      @p = pos
      @eof = false
    end

    def next_lexer(pos)
      RubyLexer.new(@source_buffer, pos)
    end

    private

    def each_token
      tag_stack = []
      @eof = false

      each_rux_token do |token|
        state, (text, pos) = token

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

    def each_rux_token(&block)
      cur_state = :tRUX_START
      last_idx = @p

      loop do
        check_eof

        chr = @source_pts[@p].chr
        cur_trans = self.class.state_table[cur_state][chr]

        unless cur_trans
          raise Rux::Lexer::TransitionError,
            "no transition found from #{cur_state} at position #{@p} while "\
            'lexing rux code'
        end

        cur_state = cur_trans.to_state
        @p += cur_trans.advance_count

        if self.class.state_table[cur_state].terminal?
          token_text = @source_buffer.source[last_idx...@p]
          yield [cur_state, [token_text, make_range(last_idx, @p)]]

          check_eof

          next_chr = @source_pts[@p].chr

          # no transition from the current state means we need to reset to the
          # start state
          unless self.class.state_table[cur_state][next_chr]
            cur_state = :tRUX_START
          end

          last_idx = @p
        end
      end
    end

    def check_eof
      if @p >= @source_pts.length
        raise Rux::Lexer::EOFError, 'unexpected end of rux input'
      end
    end

    def make_range(start, stop)
      ::Parser::Source::Range.new(@source_buffer, start, stop)
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
