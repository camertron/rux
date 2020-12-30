module Rux
  module AST
    class TagNode
      attr_reader :name, :attrs, :children

      def initialize(name, attrs)
        @name = name
        @attrs = attrs
        @children = []
      end

      def to_ruby(indent = 0)
        ''.tap do |result|
          at = attrs.map { |k, v| "#{k}: #{v.to_ruby}" }.join(', ')

          if name.start_with?(/[A-Z]/)
            result << "render(#{name}.new"

            unless attrs.empty?
              result << "({ #{at} })"
            end

            result << ')'
          else
            result << "Rux.tag('#{name}'"

            unless attrs.empty?
              result << ", { #{at} })"
            end
          end

          unless children.empty?
            rendered_children = children.map do |child|
              child.to_ruby(indent + 1)
            end

            result << " do\n#{'  ' * (indent + 1)}"
            result << rendered_children.join(" << ")
            result << "\n#{'  ' * indent}end"
          end

          result << '.html_safe'
        end
      end

      def type
        :tag
      end
    end
  end
end
