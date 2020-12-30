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

    alias :advance_orig :advance

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
      @eof = false
      curlies = 1
      populate_queue

      until @rux_token_queue.empty?
        if at_rux?
          yield @rux_token_queue.shift

          @eof = true
          _, (_, pos) = @rux_token_queue[0]

          while @eof
            yield [nil, ['$eof', pos]]
          end
        end

        token = @rux_token_queue.shift
        type, (_, _) = token

        case type
          when :tLCURLY, :tLBRACE
            curlies += 1
          when :tRCURLY, :tRBRACE
            curlies -= 1
        end

        break if curlies == 0

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
          # to start in an arbitrary position inside the source buffer. It may
          # encounter foreign rux tokens it's not expecting, etc. Best to stop
          # trying to look ahead and call it quits.
          break
        end

        break unless cur_token[0]
        @rux_token_queue << cur_token
      end
    end

    def at_rux?
      at_newline_lt? || at_not_inheritance?
    end

    def at_newline_lt?
      is?(@rux_token_queue[0], :tNL) &&
        is?(@rux_token_queue[1], :tLT) && (
          is?(@rux_token_queue[2], :tCONSTANT) ||
          is?(@rux_token_queue[2], :tIDENTIFIER)
        )
    end

    def at_not_inheritance?
      is_not?(@rux_token_queue[0], :tCONSTANT) &&
        is?(@rux_token_queue[1], :tLT) &&
        is?(@rux_token_queue[2], :tCONSTANT)
    end

    def is?(tok, sym)
      tok && tok[0] == sym
    end

    def is_not?(tok, sym)
      tok && tok[0] != sym
    end
  end
end
