module Rux
  class StateMachine
    attr_reader :source_buffer

    def initialize(state_table, source_buffer, init_pos)
      @state_table = state_table
      @pos = init_pos
      @source_buffer = source_buffer
      @generator = to_enum(:each_token)
    end

    def advance
      @generator.next
    end

    def reset_to(pos)
      @pos = pos
    end

    def eof?
      @pos >= source_buffer.source.length
    end

    private

    def each_token(&block)
      cur_state = @state_table.start_state
      last_idx = @pos

      loop do
        if eof?
          cur_trans = @state_table[cur_state][:eof]

          unless cur_trans
            raise Rux::Lexer::EOFError, 'unexpected end of input'
          end
        else
          chr = source_buffer.source[@pos].chr
          cur_trans = @state_table[cur_state][chr]

          unless cur_trans
            raise Rux::Lexer::TransitionError,
              "no transition found from #{cur_state} at position #{@pos} while "\
              'lexing rux code'
          end
        end

        cur_state = cur_trans.to_state
        @pos += cur_trans.advance_count

        if @state_table[cur_state].terminal?
          token_text = source_buffer.source[last_idx...@pos]
          yield [cur_state, [token_text, make_range(last_idx, @pos)]]

          if eof?
            raise Rux::Lexer::EOFError, 'unexpected end of input'
          end

          next_chr = source_buffer.source[@pos]

          # no transition from the current state means we need to reset to the
          # start state
          unless @state_table[cur_state][next_chr]
            cur_state = @state_table.start_state
          end

          last_idx = @pos
        end
      end
    end

    def make_range(start, stop)
      ::Parser::Source::Range.new(source_buffer, start, stop)
    end
  end
end
