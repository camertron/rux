module Rux
  module Annotations
    class RBSVisitor < AnnotationVisitor
      def visit_arg(node, level)
        "#{node.block_arg ? '&' : ''}#{node.name}: #{visit(node.type, level)}"
      end

      def visit_args(node, level)
        node.args.map { |a| visit(a, level) }.join(', ')
      end

      def visit_class_def(node, level)
        ''.tap do |result|
          type_args = if node.type.has_args?
            '['.tap do |ta|
              node.type.args.map do |type_arg|
                ta << "#{visit(type_arg.const, level)}"
              end

              ta << ']'
            end
          end

          super_class = node.super_type ? " < #{visit(node.super_type, level)}" : ''
          result << indent("class #{visit(node.type, level)}#{type_args}#{super_class}\n", level)

          lines = []

          unless node.mixins.empty?
            lines << node.mixins.map do |kind, const|
              indent("#{kind} #{visit(const)}", level + 1)
            end.join("\n")
          end

          attr_ivars = node.ivars.select(&:attr?)
          unless attr_ivars.empty?
            lines << attr_ivars.map do |ivar|
              ivar.attrs.map { |a| visit(a, level + 1) }.join("\n")
            end
          end

          lines += node.methods.flat_map do |mtd|
            visit(mtd, level + 1)
          end

          unless node.scopes.empty?
            lines << scopes.map { |scp| visit(scp, level + 1) }.join("\n")
          end

          result << lines.join("\n")
          result << indent("\nend\n", level)
        end
      end

      def visit_ivar(node, level)
        indent("#{node.ivar.name}: #{visit(node.ivar.type, level)}", level)
      end

      def visit_attr(node, level)
        indent("#{node.ivar.name}: #{visit(node.ivar.type, level)}", level)
      end

      def visit_method_def(node, level)
        ''.tap do |result|
          return_type = if node.return_type
            visit(node.return_type, level)
          else
            'void'
          end

          result << indent("def #{node.name}: (#{visit(node.args, level)}) -> #{return_type}", level)
        end
      end

      def visit_module_def(node, level)
        ''.tap do |result|
          result << indent("module #{visit(node.type)}\n", level)
          result << visit_scope(node, level + 1)
          result << indent("end\n", level)
        end
      end

      def visit_scope(node, level)
        lines = [node.mixins.map   { |kind, const| indent("#{kind} #{visit(const)}", level) }.join("\n")]
        lines << node.scopes.map   { |scp| visit(scp, level) }.join("\n")
        lines << node.methods.map  { |mtd| visit(mtd, level) }.join("\n")

        lines.reject(&:empty?).join("\n\n")
      end

      def visit_top_level_scope(node, level)
        ''.tap do |result|
          result << "# typed: #{node.type_sigil}\n\n" if node.type_sigil
          result << visit_scope(node, level)
        end
      end

      def visit_type_list(node, level)
      end

      def visit_constant(node, level)
        node.tokens.map { |_, (text, _)| text }.join
      end

      def visit_type(node, level)
        visit(node.const, level)
      end

      def visit_proc_type(node, level)
      end

      def visit_array_type(node, level)
        "Array[#{visit(node.elem_type, level)}]"
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
        node.types.map { |t| visit(t, level) }.join(' | ')
      end

      def visit_nil_type(node, level)
        'nil'
      end

      def visit_untyped_type(node, level)
        'untyped'
      end
    end
  end
end
