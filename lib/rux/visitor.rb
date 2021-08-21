module Rux
  class Visitor
    def visit(node, &block)
      node.accept(self, &block)
    end

    def visit_list(node, &block)
      visit_children(node, &block)
    end

    def visit_ruby(node, &block)
      visit_children(node, &block)
    end

    def visit_string(node, &block)
      visit_children(node, &block)
    end

    def visit_tag(node, &block)
      visit_children(node, &block)
    end

    def visit_text(node, &block)
      visit_children(node, &block)
    end

    def visit_children(node, &block)
      if node.respond_to?(:children)
        node.children.each { |child| visit(child, &block) }
      end
    end
  end
end
