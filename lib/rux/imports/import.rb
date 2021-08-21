module Rux
  module Imports
    class Import
      attr_reader :imported_consts, :from_const

      def initialize(imported_consts, from_const = nil)
        @imported_consts = imported_consts
        @from_const = from_const
      end

      def find(const)
        imported_consts.find { |ic| ic.matches?(const) }
      end
    end
  end
end
