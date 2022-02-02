module Rux
  module Annotations
    class AnnotationVisitor
      INDENT_WIDTH = 2  # spaces

      def visit(node, level)
        node.accept(self, level)
      end

      def visit_arg(node, level)
      end

      def visit_args(node, level)
      end

      def visit_class_def(node, level)
      end

      def visit_ivar(node, level)
      end

      def visit_attr(node, level)
      end

      def visit_method_def(node, level)
      end

      def visit_module_def(node, level)
      end

      def visit_type_list(node, level)
      end

      def visit_constant(node, level)
      end

      def visit_type(node, level)
      end

      def visit_proc_type(node, level)
      end

      def visit_array_type(node, level)
      end

      def visit_set_type(node, level)
      end

      def visit_hash_type(node, level)
      end

      def visit_range_type(node, level)
      end

      def visit_enumerable_type(node, level)
      end

      def visit_enumerator_type(node, level)
      end

      def visit_class_of(node, level)
      end

      def visit_self_type(node, level)
      end

      def visit_union_type(node, level)
      end

      def visit_nil_type(node, level)
      end

      def visit_untyped_type(node, level)
      end

      private

      def indent(str, level)
        indent_chars = " " * (level * INDENT_WIDTH)

        str
          .split(/(\r?\n)/)
          .map do |line|
            if line =~ /\A\r?\n\z/
              line
            else
              "#{indent_chars}#{line}"
            end
          end
          .join
      end

      def sym_quote(str)
        if str =~ /\A[^\d][\w\d]*\z/
          str
        else
          "'#{str.gsub("'", '\\\'')}'"
        end
      end

      def sym_join(key, value)
        "#{sym_quote(key)}: #{value}"
      end

      def sym(str)
        ":#{sym_quote(str)}"
      end
    end
  end
end
