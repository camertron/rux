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
        ''.tap do |result|
          at = attrs.map { |k, v| attr_to_hash_elem(k, v.to_ruby) }.join(', ')

          if name.start_with?(/[A-Z]/)
            result << "render(#{name}.new"

            unless attrs.empty?
              result << "({ #{at} })"
            end
          else
            result << "Rux.tag('#{name}'"

            unless attrs.empty?
              result << ", { #{at} }"
            end
          end

          result << ')'

          unless children.empty?
            rendered_children = children.map(&:to_ruby)
            result << " do\n"
            result << rendered_children.join(" << ")
            result << "\nend"
          end
        end
      end

      def type
        :tag
      end

      def attr_to_hash_elem(key, value)
        if key =~ /\A[\w\d]+\z/
          "#{key}: #{value}"
        else
          ":\"#{key}\" => #{value}"
        end
      end
    end
  end
end
