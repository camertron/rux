module Rux
  module Imports
    class ImportRewriter < ::Parser::AST::Processor
      attr_reader :import_list, :raise_on_missing_imports

      alias :raise_on_missing_imports? :raise_on_missing_imports

      def initialize(import_list, raise_on_missing_imports: true)
        @import_list = import_list
        @raise_on_missing_imports = raise_on_missing_imports
        @scope_stack = [Scope.new('toplevel', nil)]
        @scope_stack.last.add_unless_exists(:Rux)
      end

      def on_class(node)
        const = extract_const(node.children[0])
        push_const(const)
        super.tap { pop_const(const) }
      end

      def on_module(node)
        const = extract_const(node.children[0])
        push_const(const)
        super.tap { pop_const(const) }
      end

      def on_const(node)
        const = extract_const(node)
        return super if find_scope(const)

        resolved_const = import_list.resolve(const)

        scope_node, name = *if resolved_const
          build_const_exp(resolved_const)
        else
          if raise_on_missing_imports?
            missing = const.map(&:to_s).join('::')
            raise MissingConstantError, "Cannot find constant '#{missing}' " \
              "on line #{node.loc.line}, do you need to import it?"
          end

          node
        end

        node.updated(nil, [
          scope_node, name
        ])
      end

      private

      def find_scope(const)
        cur = @scope_stack.last

        while cur
          return cur if cur.include?(const)
          cur = cur.parent
        end

        nil
      end

      def push_const(const)
        const.each do |c|
          cur_scope = @scope_stack.last
          next_scope = cur_scope.add_unless_exists(c)
          @scope_stack.push(next_scope)
        end
      end

      def pop_const(const)
        const.each { |_c| @scope_stack.pop }
      end

      def extract_const(node)
        return [] unless node
        scope_node, name = *node
        extract_const(scope_node) + [name]
      end

      def build_const_exp(consts)
        consts.inject(nil) do |exp, const|
          s(:const, exp, const)
        end
      end

      def s(type, *children)
        ::Parser::AST::Node.new(type, children)
      end
    end
  end
end
