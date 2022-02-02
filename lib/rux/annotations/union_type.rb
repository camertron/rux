module Rux
  module Annotations
    class UnionType < Annotation
      attr_reader :types

      def initialize(types)
        @types = types
      end

      def sig
        "T.any(#{types.map(&:sig).join(', ')})"
      end

      def accept(visitor, level)
        visitor.visit_union_type(self, level)
      end
    end
  end
end
