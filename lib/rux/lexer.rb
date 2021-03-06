module Rux
  class Lexer
    class EOFError < StandardError; end
    class TransitionError < StandardError; end

    attr_reader :source_buffer

    def initialize(source_buffer)
      @source_buffer = source_buffer
      @stack = [RubyLexer.new(source_buffer, 0)]
      @generator = to_enum(:each_token)
    end

    def advance
      @generator.next
    rescue StopIteration
      [nil, ['$eof']]
    end

    private

    def each_token
      @p = 0

      while true
        begin
          token = current.advance
        rescue StopIteration
          # This error means the current lexer has run it's course and should
          # be considered finished. The lexer should have already yielded a
          # :tRESET token to position the previous lexer (i.e. the one
          # logically before it in the stack) at the place it left off.
          @stack.pop
          break unless current  # no current lexer means we're done
          current.reset_to(@p)
          next
        end

        type, (_, pos) = token
        break unless pos

        unless type
          @stack.push(current.next_lexer(pos.begin_pos))
          next
        end

        case type
          when :tRESET
            @p = pos.begin_pos
          when :tSKIP
            next
          else
            yield token

            @p = pos.end_pos
        end
      end
    end

    def current
      @stack.last
    end
  end
end
