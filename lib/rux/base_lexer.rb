module Rux
  class BaseLexer < ::Parser::Lexer
    # These are populated when ::Parser::Lexer loads and are therefore
    # not inherited. We have to copy them over manually.
    ::Parser::Lexer.instance_variables.each do |ivar|
      instance_variable_set(ivar, ::Parser::Lexer.instance_variable_get(ivar))
    end

    def initialize(source_buffer, init_pos, context)
      super(ruby_version)
      self.source_buffer = source_buffer
      context[:comments] = self.comments = []
      reset_to(init_pos)
    end

    def reset_to(pos)
      @ts = @te = @p = pos
    end

    def advance
      token = super
      token
    end

    private

    def ruby_version
      @ruby_version ||= RUBY_VERSION
        .split('.')[0..-2]
        .join('')
        .to_i
    end
  end
end
