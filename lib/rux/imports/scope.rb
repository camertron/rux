module Rux
  module Imports
    class Scope
      attr_reader :name, :parent, :scopes

      def initialize(name, parent)
        @name = name
        @parent = parent
        @scopes = {}
      end

      def add_unless_exists(name)
        unless scopes.include?(name)
          scopes[name] = self.class.new(name, self)
        else
          scopes[name]
        end
      end

      def include?(const)
        scope = const.inject(self) do |scope, c|
          break unless scope
          scope.scopes[c]
        end

        !scope.nil?
      end
    end
  end
end
