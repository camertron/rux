require 'cgi'

module Rux
  class DefaultVisitor < Visitor
    def visit_list(node)
      node.children.map { |child| visit(child) }.join
    end

    def visit_ruby(node)
      node.code
    end

    def visit_string(node)
      node.str
    end

    def visit_tag(node)
      ''.tap do |result|
        at = node.attrs.map { |k, v| Utils.attr_to_hash_elem(k, visit(v)) }.join(', ')

        if node.name.start_with?(/[A-Z]/)
          result << "render(#{node.name}.new"

          unless node.attrs.empty?
            result << "({ #{at} })"
          end
        else
          result << "Rux.tag('#{node.name}'"

          unless node.attrs.empty?
            result << ", { #{at} }"
          end
        end

        result << ')'

        unless node.children.empty?
          rendered_children = node.children.map do |child|
            visit(child)
          end

          result << " do\n"
          result << rendered_children.join(" << ")
          result << "\nend"
        end
      end
    end

    def visit_text(node)
      "\"#{CGI.escape_html(node.text)}\""
    end
  end
end
