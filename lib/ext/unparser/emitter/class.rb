module Rux
  module UnparserClassDispatchPatch
    private

    def dispatch
      write_loc('class', node.location.keyword.to_range)
      write(' ')
      visit(name)
      emit_superclass
      emit_optional_body(body)
      k_end
    end
  end
end


module Unparser
  class Emitter
    class Class < self
      prepend Rux::UnparserClassDispatchPatch
    end
  end
end
