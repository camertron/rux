module Rux
  class BaseLexer < LexerInterface
    def initialize(source_buffer, init_pos, context)
      super()

      self.source_buffer = source_buffer
      context[:comments] = self.comments = []
      reset_to(init_pos)
    end

    def reset_to(pos)
      @ts = @te = @p = pos
    end
  end
end
