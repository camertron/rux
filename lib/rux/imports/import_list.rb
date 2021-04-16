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
        import, resolved_const = find(const)
        return nil unless import && resolved_const

        [
          *(import.from_const&.const || []),
          *resolved.const
        ]
      end

      def find(const)
        imports.each do |import|
          if resolved = import.resolve_const(const)
            return import, resolved
          end
        end

        []
      end
    end
  end
end
