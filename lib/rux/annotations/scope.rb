module Rux
  module Annotations
    class Scope < Annotation
      attr_reader :type, :methods, :scopes, :mixins

      def initialize(type)
        @type = type
        @methods = []
        @scopes = []
        @mixins = []
      end

      def to_rbi(level)
        lines = [mixins.map   { |kind, const| indent("#{kind} #{const}", level) }.join("\n")]
        lines << scopes.map   { |scp| scp.to_rbi(level) }.join("\n")
        lines << methods.map  { |mtd| mtd.to_rbi(level) }.join("\n")

        lines.reject(&:empty?).join("\n\n")
      end
    end
  end
end
