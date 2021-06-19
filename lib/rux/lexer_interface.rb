module Rux
  # Anything that inherits from this class will behave like a ::Parser::Lexer
  # and can be used by ::Parser instances to parse a stream of arbitrary tokens.
  class LexerInterface < ::Parser::Lexer
    def self.inherited(base)
      # These are populated when ::Parser::Lexer loads and are therefore not
      # inherited. We have to copy them over manually. Super jank, but it works.
      ::Parser::Lexer.instance_variables.each do |ivar|
        base.instance_variable_set(ivar, ::Parser::Lexer.instance_variable_get(ivar))
      end
    end

    def initialize
      super(ruby_version)
    end

    private

    def ruby_version
      @ruby_version ||= RUBY_VERSION
        .split('.')
        .take(2)
        .join
        .to_i
    end
  end
end
