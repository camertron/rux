module Rux
  module Imports
    class ImportInfo
      attr_reader :list, :sigil

      def initialize(import_list, sigil)
        @list = import_list
        @sigil = sigil
      end

      def resolve(const)
        list.resolve(const)
      end
    end
  end
end
