module Rux
  class RubyParser
    attr_reader :lexer

    def initialize(lexer)
      @lexer = lexer
    end

    def parse(buffer)
      parser = ::Parser::CurrentRuby.new
      parser.diagnostics.all_errors_are_fatal = true
      parser.instance_variable_set(:@lexer, lexer)
      lexer.diagnostics = parser.diagnostics
      lexer.static_env  = parser.static_env
      lexer.context     = parser.context
      parser.parse(buffer)
    end
  end
end
