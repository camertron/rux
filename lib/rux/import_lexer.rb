module Rux
  class ImportLexer
    def initialize(source_buffer, init_pos)
      @p = init_pos
      @source_buffer = source_buffer
      @source = @source_buffer.source
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
      # import {Foo as Bar} from Baz
    end
  end
end
