module Rux
  module Imports
    class ImportRewriter < ::Parser::AST::Processor
      attr_reader :buffer, :import_info

      def initialize(buffer, import_info)
        @buffer = buffer
        @import_info = import_info
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
        return super if import_info.sigil == Sigil.s_false

        const = extract_const(node)
        return super if find_scope(const)

        resolved_const = import_info.resolve(const)

        scope_node, name = *if resolved_const
          if resolved_const.as_const
            build_const_exp(resolved_const.full_const)
          elsif resolved_const.from_const
            exp = build_const_exp(resolved_const.from_const || [])
            s(:const, exp, node.children[1])
          else
            node
          end
        else
          if raise_on_missing?
            missing = const.map(&:to_s).join('::')
            raise MissingConstantError.new(
              "Cannot find constant '#{missing}' on line #{node.loc.line}, "\
                "do you need to import it?",
              const
            )
          end

          node
        end

        node.updated(nil, [
          scope_node, name
        ])
      end

      private

      def raise_on_missing?
        import_info.sigil == Sigil.s_strict
      end

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
          s(:const, exp, const, location: empty_location)
        end
      end

      def empty_location
        ::Parser::Source::Map::Constant.new(
          *Array.new(3) { ::Parser::Source::Range.new(buffer, -1, -1) }
        )
      end

      def s(type, *children, **properties)
        ::Parser::AST::Node.new(type, children, properties)
      end
    end
  end
end
