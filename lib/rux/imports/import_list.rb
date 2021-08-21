module Rux
  module Imports
    class ImportList
      attr_reader :imports

      def initialize
        @imports = []
      end

      def add(import)
        @imports << import
      end

      def resolve(const)
        import, imported_const = find(const)
        return nil unless import && imported_const

        ResolvedConst.new(import, imported_const)
      end

      private

      def find(const)
        imports.each do |import|
          if imported_const = import.find(const)
            return import, imported_const
          end
        end

        []
      end
    end
  end
end
