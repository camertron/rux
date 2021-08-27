module Rux
  module UnparserVariableDispatchPatch
    private

    def dispatch
      write_loc(name.to_s, node.location.name.to_range)
    end
  end

  module UnparserConstDispatchPatch
    private

    def dispatch
      emit_scope
      write_loc(name.to_s, node.location.name.to_range)
    end

    def emit_scope
      return unless scope

      visit(scope)
      write_loc('::', node.location.double_colon.to_range) unless n_cbase?(scope)
    end
  end

  module UnparserNthRefDispatchPatch
    private

    def dispatch
      write_loc([Unparser::Emitter::NthRef::PREFIX, name.to_s], node.location.expression.to_range)
    end
  end
end


module Unparser
  class Emitter
    class Variable < self
      prepend Rux::UnparserVariableDispatchPatch
    end

    class Const < self
      prepend Rux::UnparserConstDispatchPatch
    end

    class NthRef < self
      prepend Rux::UnparserNthRefDispatchPatch
    end
  end
end
