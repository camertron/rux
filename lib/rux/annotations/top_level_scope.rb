module Rux
  module Annotations
    class TopLevelScope < Scope
      attr_accessor :type_sigil

      def initialize
        super('(toplevel)')
      end

      def to_rbi
        ''.tap do |result|
          result << "# typed: #{type_sigil}\n\n" if type_sigil
          result << super(0)
        end
      end
    end
  end
end
