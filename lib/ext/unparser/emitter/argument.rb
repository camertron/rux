module Rux
  module UnparserArgDispatchPatch
    private

    def dispatch
      write_loc(name.to_s, node.location.name.to_range)
    end
  end
end


module Unparser
  class Emitter
    class Argument < self
      prepend Rux::UnparserArgDispatchPatch
    end
  end
end
