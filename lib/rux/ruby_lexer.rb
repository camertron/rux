module Rux
  class RubyLexer
    LOOKAHEAD = 3

    attr_reader :context

    def initialize(source_buffer, init_pos, context)
      @source_buffer = source_buffer
      @lexer = AnnotationLexer.new(source_buffer, init_pos, context)
      @generator = to_enum(:each_token)
      @rux_token_queue = []
      @context = context
    end

    def advance
      @generator.next
    end

    def reset_to(pos)
      @lexer.reset_to(pos)
      @eof = false
      @rux_token_queue.clear
      populate_queue
    end

    def next_lexer(pos)
      RuxLexer.new(@source_buffer, pos, context)
    end

    private

    def each_token(&block)
      # We detect whether or not we're at the beginning of a rux tag by looking
      # ahead by 1 token; that's why the first element in @rux_token_queue is
      # yielded immediately. If the lexer _starts_ at a rux tag however,
      # lookahead is a lot more difficult. To mitigate, we insert a dummy skip
      # token here. That way, at_rux? checks the right tokens in the queue and
      # correctly identifies the start of a rux tag.
      @rux_token_queue << [:tSKIP, ['$skip', make_range(-1, -1)]]

      @eof = false
      curlies = 1
      populate_queue

      until @rux_token_queue.empty?
        if at_rux?
          yield @rux_token_queue.shift

          @eof = true
          _, (_, pos) = @rux_token_queue[0]

          # @eof is set to false by reset_to above, which is called after
          # popping the previous lexer off the lexer stack (see lexer.rb)
          while @eof
            yield [nil, ['$eof', pos]]
          end
        end

        token = @rux_token_queue.shift
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

        populate_queue
      end
    end

    def populate_queue
      until @rux_token_queue.size >= LOOKAHEAD
        begin
          cur_token = @lexer.advance
        rescue NoMethodError
          # Internal lexer errors can happen since we're asking the ruby lexer
          # to start at an arbitrary position inside the source buffer. It may
          # encounter foreign rux tokens it's not expecting, etc. Best to stop
          # trying to look ahead and call it quits.
          break
        end

        break unless cur_token[0]
        @rux_token_queue << cur_token
      end
    end

    def at_rux?
      at_lt? && !at_inheritance?
    end

    def at_lt?
      is?(@rux_token_queue[1], :tLT) && (
        is?(@rux_token_queue[2], :tCONSTANT) ||
        is?(@rux_token_queue[2], :tIDENTIFIER)
      )
    end

    def at_inheritance?
      is?(@rux_token_queue[0], :tCONSTANT) &&
        is?(@rux_token_queue[1], :tLT) &&
        is?(@rux_token_queue[2], :tCONSTANT)
    end

    def is?(tok, sym)
      tok && tok[0] == sym
    end

    def is_not?(tok, sym)
      tok && tok[0] != sym
    end

    def make_range(start, stop)
      ::Parser::Source::Range.new(@source_buffer, start, stop)
    end
  end
end
