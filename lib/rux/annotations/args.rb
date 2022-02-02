module Rux
  module Annotations
    class Args < Annotation
      attr_reader :args

      def initialize(args)
        @args = args
      end

      def to_ruby
        args.map(&:to_ruby).join(', ')
      end

      def sig
        args.map(&:sig).join(', ')
      end

      def empty?
        args.empty?
      end

      def accept(visitor, level)
        visitor.visit_args(self, level)
      end
    end
  end
end
