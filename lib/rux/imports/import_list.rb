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
        imports.each do |import|
          if resolved = import.resolve_const(const)
            return [
              *(import.from_const&.const || []),
              *resolved.const
            ]
          end
        end

        nil
      end
    end
  end
end
