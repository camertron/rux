module Rux
  class TokenLexer < LexerInterface
    attr_reader :ast, :buffer, :visitor

    def initialize(ast, buffer, visitor)
      super()

      @ast = ast
      @buffer = buffer
      @visitor = visitor
      @generator = to_enum(:each_token)
    end

    def advance
      @generator.next
    rescue StopIteration
      loc = ::Parser::Source::Range.new(
        buffer, buffer.source.length, buffer.source.length
      )

      # The Parser gem expects the EOF token to be false instead of nil.
      # This is somewhat confusing because Parser _used_ to use nil,
      # which is why the rest of rux uses nil too. ¯\_(ツ)_/¯
      [false, ['$eof', loc]]
    end

    private

    def each_token(&block)
      visitor.visit(ast) do |token|
        type, (text, pos) = token
        pos ||= ::Parser::Source::Range.new(buffer, -1, -1)
        yield [type, [text, pos]]
      end
    end
  end
end
