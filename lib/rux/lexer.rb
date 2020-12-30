module Rux
  class Lexer
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
          @stack.pop
          break unless current
          current.reset_to(@p)
          next
        end

        type, (_, pos) = token

        unless type
          @stack.push(current.next_lexer(pos.begin_pos))
          next
        end

        yield token

        @p = pos.end_pos
      end
    end

    def current
      @stack.last
    end
  end
end
