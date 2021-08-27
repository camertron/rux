module Rux
  module UnparserDefDispatchPatch
    private

    def dispatch
      write_loc('def', node.location.keyword.to_range)
      write(' ')
      emit_name
      emit_arguments
      emit_optional_body_ensure_rescue(body)
      k_end
    end
  end

  module UnparserDefInstanceDispatchPatch
    private

    def emit_name
      write_loc(name.to_s, node.location.name.to_range)
    end
  end

  module UnparserDefSingletonDispatchPatch
    private

    def emit_name
      conditional_parentheses(!subject_without_parens?) do
        visit(subject)
      end
      write_loc('.', node.location.operator.to_range)
      write_loc(name.to_s, node.location.name.to_range)
    end
  end
end


module Unparser
  class Emitter
    class Def < self
      prepend Rux::UnparserDefDispatchPatch

      class Instance < self
        prepend Rux::UnparserDefInstanceDispatchPatch
      end

      class Singleton < self
        prepend Rux::UnparserDefSingletonDispatchPatch
      end
    end
  end
end
