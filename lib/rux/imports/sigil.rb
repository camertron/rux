module Rux
  module Imports
    class Sigil
      class << self
        def find(str)
          [s_false, s_true, s_strict].find do |sigil|
            sigil.name == str
          end
        end

        # imports totally ignored
        def s_false
          @s_false ||= Sigil.send(:new, 'false', 0)
        end

        # imports used for aliasing, but no errors raised if missing
        def s_true
          @s_true ||= Sigil.send(:new, 'true', 1)
        end

        # imports used for aliasing, missing imports will raise an error
        def s_strict
          @s_ignore ||= Sigil.send(:new, 'strict', 2)
        end

        def default
          s_true
        end
      end

      include Comparable

      attr_reader :name, :severity

      def <=>(other)
        return nil unless other.is_a?(self.class)

        if severity > other.severity
          1
        elsif severity < other.severity
          -1
        else
          0
        end
      end

      private

      def initialize(name, severity)
        @name = name
        @severity = severity
      end
    end
  end
end
