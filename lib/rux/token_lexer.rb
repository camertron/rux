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
      [nil, ['$eof']]
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
