module Rux
  module Annotations
    class Arg < Annotation
      attr_reader :name, :type, :block_arg, :default_value_tokens

      def initialize(name, type, block_arg, default_value_tokens)
        @name = name
        @type = type
        @block_arg = block_arg
        @default_value_tokens = default_value_tokens
      end

      def to_ruby
        "#{block_arg ? '&' : ''}#{name}"
      end

      def sig
        sym_join(name, type.sig)
      end

      def accept(visitor, level)
        visitor.visit_arg(self, level)
      end
    end
  end
end
