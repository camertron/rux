module Rux
  module UnparserEmitterPatch
    include Unparser::Anima.new(:buffer, :comments, :node, :local_variable_scope, :callback)

    class << self
      def emitter(buffer:, comments:, node:, local_variable_scope:, callback:)
        type = node.type

        klass = Unparser::Emitter::REGISTRY.fetch(type) do
          fail UnknownNodeError, "Unknown node type: #{type.inspect}"
        end

        klass.new(
          buffer:               buffer,
          comments:             comments,
          local_variable_scope: local_variable_scope,
          node:                 node,
          callback:             callback
        )
      end
    end
  end
end


module Unparser
  class Emitter
    prepend Rux::UnparserEmitterPatch
  end
end
