require 'cgi'

module Rux
  class DefaultVisitor < Visitor
    def initialize
      @render_stack = []
    end

    def visit_root(node)
      visit_list(node.list)
    end

    def visit_list(node)
      ''.tap do |result|
        node.children.each { |child| result << visit(child) }
      end
    end

    def visit_ruby(node)
      node.code
    end

    def visit_string(node)
      case node.quote_type
        when :single
          "'#{node.str}'"
        else
          "\"#{node.str}\""
      end
    end

    def visit_tag(node)
      ''.tap do |result|
        block_arg = if (as = node.attrs.get('as'))
          visit(as.value)
        end

        block_arg ||= "rux_block_arg#{@render_stack.size}"

        if node.slot_component?
          result << "(#{parent_render[:block_arg]}.#{node.slot_method}"

          unless node.attrs.empty?
            result << "(#{visit(node.attrs)})"
          end
        elsif node.component?
          result << "render(#{node.name}.new"

          unless node.attrs.empty?
            result << "(#{visit(node.attrs)})"
          end

          result << ')'
        else
          result << "Rux.tag('#{node.name}'"

          unless node.attrs.empty?
            result << ", { #{visit(node.attrs)} }"
          end

          result << ')'
        end

        @render_stack.push({
          component_name: node.name,
          block_arg: block_arg
        })

        if node.children.size > 0
          result << " { "
          result << "|#{block_arg}| " if block_arg && node.component?
          result << "Rux.create_buffer.tap { |_rux_buf_| "

          result << visit_tag_children(node).join
          result << " }.to_s }"
        end

        # don't pass instances of ViewComponent::Slot to _rux_buf_#<< by wrapping
        # the slot setter return value in (retval; nil)
        if node.slot_component?
          result << "; nil)"
        end

        @render_stack.pop
      end
    end

    def visit_tag_children(node)
      node.children.map do |child|
        append_statement_for(child)
      end
    end

    def append_statement_for(node)
      if node.is_a?(AST::TextNode)
        "_rux_buf_.safe_append(#{visit(node).strip.chomp(';')});"
      else
        "_rux_buf_.append(#{visit(node).strip.chomp(';')});"
      end
    end

    def visit_attrs(node)
      visited_attrs = node.attrs.each_with_object([]) do |attr, memo|
        memo << visit(attr) unless attr.name == "as"
      end

      visited_attrs.join(", ")
    end

    def visit_attr(node)
      if node.ruby_code?
        node.code
      else
        Utils.attr_to_hash_elem(
          node.name,
          visit(node.value),
          slugify: node.tag_node.component?
        )
      end
    end

    def visit_fragment(node)
      ''.tap do |result|
        result << "Rux.create_buffer.tap { |_rux_buf_| "

        node.children.each do |child|
          result << append_statement_for(child)
        end

        result << " }.to_s;"
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
