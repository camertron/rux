require 'cgi'

module Rux
  class DefaultVisitor < Visitor
    def initialize
      @render_stack = []
    end

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

        block_arg ||= "rux_block_arg#{@render_stack.size}"

        at = node.attrs.each_with_object([]) do |(k, v), ret|
          next if k == 'as'
          ret << Utils.attr_to_hash_elem(k, visit(v), slugify: node.component?)
        end

        if node.slot_component?
          result << "#{parent_render[:block_arg]}.#{node.slot_method}"

          unless node.attrs.empty?
            result << "(#{at.join(', ')})"
          end
        elsif node.component?
          result << "render(#{node.name}.new"

          unless node.attrs.empty?
            result << "(#{at.join(', ')})"
          end

          result << ')'
        else
          result << "Rux.tag('#{node.name}'"

          unless node.attrs.empty?
            result << ", { #{at.join(', ')} }"
          end

          result << ')'
        end

        @render_stack.push({
          component_name: node.name,
          block_arg: block_arg
        })

        if node.children.size > 1
          result << " { "
          result << "|#{block_arg}| " if block_arg && node.component?
          result << "Rux.create_buffer.tap { |_rux_buf_| "

          node.children.each do |child|
            result << "_rux_buf_ << #{visit(child).strip};"
          end

          result << " }.to_s }"
        elsif node.children.size == 1
          result << ' { '
          result << "|#{block_arg}| " if block_arg && node.component?
          result << visit(node.children.first).strip
          result << ' }'
        end

        @render_stack.pop
      end
    end

    def visit_text(node)
      "\"#{CGI.escape_html(node.text)}\""
    end

    private

    def parent_render
      @render_stack.last
    end
  end
end
