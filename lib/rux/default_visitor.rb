require 'cgi'

module Rux
  class DefaultVisitor < Visitor
    WHITESPACE_REGEX = /\A\s+\z/

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
            result << "(#{at.join(', ')})"
          end
        else
          result << "Rux.tag('#{node.name}'"

          unless node.attrs.empty?
            result << ", { #{at.join(', ')} }"
          end
        end

        result << ')'

        children = children_from_tag_node(node)

        if children.size > 1
          result << " { "
          result << "|#{block_arg}| " if block_arg
          result << "Rux.create_buffer.tap { |_rux_buf_| "

          children.each do |child|
            result << "_rux_buf_ << #{visit(child).strip};"
          end

          result << " }.to_s }"
        elsif children.size == 1
          result << ' { '
          result << "|#{block_arg}| " if block_arg
          result << visit(children.first).strip
          result << ' }'
        end
      end
    end

    def visit_text(node)
      CGI.escape_html(node.text).inspect
    end

    private

    def children_from_tag_node(node)
      return node.children if Parser::WHITESPACE_SENSITIVE_TAGS.include?(node.name)

      first_child, *middle_children, last_child = *node.children

      children = [
        is_ws?(first_child) ? nil : first_child,
        *middle_children,
        is_ws?(last_child) ? nil : last_child
      ]

      children.compact!

      children.each_cons(3) do |prev_child, cur_child, next_child|
        text_between_tags =
          prev_child.type == :tag &&
          cur_child.type == :text &&
          next_child.type == :tag

        if text_between_tags && is_ws?(cur_child)
          children.delete(cur_child)
        end
      end

      children
    end

    def is_ws?(node)
      node && node.type == :text && node.text =~ WHITESPACE_REGEX
    end

    def last_node
      @node_stack.last[-2]
    end
  end
end
