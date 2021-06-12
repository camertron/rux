module Rux
  class VisitContext
    attr_reader :token_sink, :source_map

    def initialize(token_sink)
      @token_sink = token_sink
      @source_map = {}
    end

    def <<(token)
      token_sink.call(token)
    end
  end
end
