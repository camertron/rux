module Rux
  module UnparserModuleDispatchPatch
    private

    def dispatch
      write_loc('module', node.location.keyword.to_range)
      write(' ')
      visit(name)
      emit_optional_body(body)
      k_end
    end
  end
end


module Unparser
  class Emitter
    class Module < self
      prepend Rux::UnparserModuleDispatchPatch
    end
  end
end
