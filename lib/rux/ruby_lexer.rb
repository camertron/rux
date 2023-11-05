module Rux
  class RubyLexer < ::Parser::Lexer
    # These are populated when ::Parser::Lexer loads and are therefore
    # not inherited. We have to copy them over manually.
    ::Parser::Lexer.instance_variables.each do |ivar|
      instance_variable_set(ivar, ::Parser::Lexer.instance_variable_get(ivar))
    end

    LOOKAHEAD = 3

    def initialize(source_buffer, init_pos)
      super(ruby_version)

      self.source_buffer = source_buffer
      @generator = to_enum(:each_token)
      @rux_token_queue = []
      @p = init_pos
    end

    alias_method :advance_orig, :advance

    def advance
      @generator.next
    end

    def reset_to(pos)
      @ts = @te = @p = pos
      @eof = false
      @rux_token_queue.clear
      populate_queue
    end

    def next_lexer(pos)
      RuxLexer.new(@source_buffer, pos)
    end

    private

    def ruby_version
      @ruby_version ||= RUBY_VERSION
        .split('.')[0..-2]
        .join('')
        .to_i
    end

    def each_token(&block)
      # We detect whether or not we're at the beginning of a rux tag by looking
      # ahead by 1 token; that's why the first element in @rux_token_queue is
      # yielded immediately. If the lexer _starts_ at a rux tag however,
      # lookahead is a lot more difficult. To mitigate, we insert a dummy skip
      # token here. That way, at_rux? checks the right tokens in the queue and
      # correctly identifies the start of a rux tag.
      @rux_token_queue << [:tSKIP, ['$skip', make_range(@p, @p)]]

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
          cur_token = advance_orig
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
        is?(@rux_token_queue[2], :tGT) ||
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
