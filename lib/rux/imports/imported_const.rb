module Rux
  module Imports
    class ImportedConst
      class << self
        def parse(const_str, as_const_str)
          new(split(const_str), as_const_str ? split(as_const_str) : nil)
        end

        private

        def split(str)
          str.split('::').map(&:to_sym)
        end
      end

      attr_reader :const, :as_const

      def initialize(const, as_const)
        @const = const
        @as_const = as_const
      end

      def matches?(other_const)
        if as_const
          other_const == as_const
        else
          other_const == const
        end
      end
    end
  end
end
