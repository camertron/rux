module Rux
  class RubyLexer
    attr_reader :context

    def initialize(source_buffer, init_pos, context)
      @source_buffer = source_buffer
      @lexer = BaseLexer.new(source_buffer, init_pos, context)
      @generator = to_enum(:each_token)
      @matcher = TokenMatcher.new(@lexer)
      @context = context
    end

    def advance
      @generator.next
    end

    def reset_to(pos)
      @lexer.reset_to(pos)
      @eof = false
      @matcher.clear
    end

    def next_lexer(pos)
      if @matcher.at_import?
        ImportLexer.new(@source_buffer, pos, context)
      else
        RuxLexer.new(@source_buffer, pos, context)
      end
    end

    private

    def each_token(&block)
      @eof = false
      curlies = 1

      until @matcher.empty?
        if @matcher.at_rux? || @matcher.at_import?
          @eof = true
          _, (_, pos) = @matcher.current

          # @eof is set to false by reset_to above, which is called after
          # popping the previous lexer off the lexer stack (see lexer.rb)
          while @eof
            yield [nil, ['$eof', pos]]
          end
        elsif @matcher.at_inheritance?
          2.times { yield @matcher.dequeue }
        end

        token = @matcher.dequeue
        type, (_, pos) = token

        case type
          when :tLCURLY, :tLBRACE
            curlies += 1
          when :tRCURLY, :tRBRACE
            curlies -= 1
        end

        # if curlies are balanced, we're done lexing ruby code, so yield a
        # reset token to tell the system where we stopped, then break to stop
        # our enumerator (will raise a StopIteration)
        if curlies == 0
          yield [:tRESET, ['$eof', pos]]
          break
        end

        yield token
      end
    end
  end
end
