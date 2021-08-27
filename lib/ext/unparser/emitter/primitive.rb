require 'unparser/emitter/primitive'

# this hash is frozen so we have to dup it :(
Unparser::Emitter::REGISTRY = Unparser::Emitter::REGISTRY.dup
Unparser::Emitter::REGISTRY.delete(:sym)
Unparser::Emitter::REGISTRY.delete(:str)

module Unparser
  class Emitter
    class Primitive < self
      class Str < self

        handle :str

        private

        def dispatch
          new_loc = buffer.append(value.inspect)
          return unless callback

          new_loc_adjusted = (new_loc.first + 1)...(new_loc.last - 1)
          callback.call(buffer, node.location.expression.to_range, new_loc_adjusted)
        end

      end # Str

      class Sym < self

        handle :sym

        private

        def dispatch
          write_loc(value.inspect, node.location.expression.to_range)
        end

      end # Sym
    end
  end
end

Unparser::Emitter::REGISTRY.freeze
