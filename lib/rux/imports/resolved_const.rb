module Rux
  module Imports
    class ResolvedConst
      attr_reader :import, :imported_const

      def initialize(import, imported_const)
        @import = import
        @imported_const = imported_const
      end

      def full_const
        @full_const ||= [
          *(import.from_const&.const || []),
          *imported_const.const
        ]
      end

      def as_const
        imported_const.as_const
      end

      def from_const
        import.from_const&.const
      end
    end
  end
end
