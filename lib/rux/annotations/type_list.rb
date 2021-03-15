module Rux
  module Annotations
    class TypeList < Annotation
      include Enumerable

      attr_reader :types

      def initialize(types)
        @types = types
      end

      def empty?
        types.empty?
      end

      def each(&block)
        types.each(&block)
      end
    end
  end
end
