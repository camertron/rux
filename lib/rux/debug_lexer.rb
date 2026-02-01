module Rux
  class DebugLexer
    def initialize(...)
      @lexer = Lexer.new(...)
      @tokens = @lexer.to_a
      @counter = -1
    end

    def source_buffer
      @lexer.source_buffer
    end

    def advance
      @counter += 1

      if @counter >= @tokens.size
        [nil, ['$eof']]
      else
        @tokens[@counter]
      end
    end
  end
end
