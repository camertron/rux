module Rux
  class Visitor
    def visit(node)
      node.accept(self)
    end

    def visit_root(node)
      visit_children(node)
    end

    def visit_list(node)
      visit_children(node)
    end

    def visit_ruby(node)
      visit_children(node)
    end

    def visit_string(node)
      visit_children(node)
    end

    def visit_tag(node)
      visit_children(node)
    end

    def visit_attrs(node)
      visit_children(node)
    end

    def visit_attr(node)
      visit_children(node)
    end

    def visit_fragment(node)
      visit_children(node)
    end

    def visit_text(node)
      visit_children(node)
    end

    def visit_children(node)
      if node.respond_to?(:children)
        node.children.each { |child| visit(child) }
      end
    end
  end
end
