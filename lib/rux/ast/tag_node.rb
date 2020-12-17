module Rux
  module AST
    class TagNode
      attr_reader :name, :attrs, :children

      def initialize(name, attrs)
        @name = name
        @attrs = attrs
        @children = []
      end

      def to_ruby
        "".tap do |result|
          if name.start_with?(/[A-Z]/)
            result << "#{name}.new("
          else
            result << "::Rux.tag('#{name}', "
          end

          if attrs.empty?
            result << "{}"
          else
            at = attrs.map { |k, v| "#{k}: #{v.to_ruby}" }.join(', ')
            result << "{ #{at} }"
          end

          result << ") { #{children.map(&:to_ruby).join(" + ")} }.render"
        end
      end
    end
  end
end
