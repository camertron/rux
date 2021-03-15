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
    end
  end
end
