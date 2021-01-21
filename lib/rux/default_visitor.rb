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
        block_arg = if (as = node.attrs['as'])
          visit(as)
        end

        at = node.attrs.each_with_object([]) do |(k, v), ret|
          next if k == 'as'
          ret << Utils.attr_to_hash_elem(k, visit(v))
        end

        if node.name.start_with?(/[A-Z]/)
          result << "render(#{node.name}.new"

          unless node.attrs.empty?
            result << "({ #{at.join(', ')} })"
          end
        else
          result << "Rux.tag('#{node.name}'"

          unless node.attrs.empty?
            result << ", { #{at.join(', ')} }"
          end
        end

        result << ')'

        if node.children.size > 1
          result << " { "
          result << "|#{block_arg}| " if block_arg
          result << "Rux.create_buffer.tap { |_rux_buf_| "

          node.children.each do |child|
            result << "_rux_buf_ << #{visit(child).strip};"
          end

          result << " }.to_s }"
        elsif node.children.size == 1
          result << ' { '
          result << "|#{block_arg}| " if block_arg
          result << visit(node.children.first).strip
          result << ' }'
        end
      end
    end

    def visit_text(node)
      "\"#{CGI.escape_html(node.text)}\""
    end
  end
end
