module Rux
  module Annotations
    class Arg < Annotation
      attr_reader :name, :type, :block_arg

      def initialize(name, type, block_arg)
        @name = name
        @type = type
        @block_arg = block_arg
      end

      def to_ruby
        "#{block_arg ? '&' : ''}#{name}"
      end

      def sig
        sym_join(name, type.sig)
      end
    end
  end
end
