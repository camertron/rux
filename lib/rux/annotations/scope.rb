module Rux
  module Annotations
    class Scope < Annotation
      attr_reader :type, :methods, :scopes, :ivars, :mixins

      def initialize(type)
        @type = type
        @methods = []
        @scopes = []
        @ivars = []
        @mixins = []
      end

      def to_rbi(level)
        lines = [mixins.map   { |kind, const| indent("#{kind} #{const.to_ruby}", level) }.join("\n")]
        lines << scopes.map   { |scp| scp.to_rbi(level) }.join("\n")
        lines << methods.map  { |mtd| mtd.to_rbi(level) }.join("\n")

        lines.reject(&:empty?).join("\n\n")
      end

      def to_rbs(level)
        lines = [mixins.map   { |kind, const| indent("#{kind} #{const.to_ruby}", level) }.join("\n")]
        lines << scopes.map   { |scp| scp.to_rbs(level) }.join("\n")
        lines << methods.map  { |mtd| mtd.to_rbs(level) }.join("\n")

        lines.reject(&:empty?).join("\n\n")
      end

      def accept(visitor, level)
        visitor.visit_scope(self, level)
      end

      def top_level_scope?
        false
      end
    end
  end
end
