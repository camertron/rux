module Rux
  class AnnotationLexer
    class UnexpectedTokenError < StandardError; end

    include Annotations

    attr_reader :source_buffer, :context

    def initialize(source_buffer, init_pos, context)
      @source_buffer = source_buffer
      @lexer = BaseLexer.new(source_buffer, init_pos, context)
      @generator = to_enum(:each_token)
      @current = get_next
      @context = context
      @context[:annotations] ||= TopLevelScope.new
      @top_level_scope = @context[:annotations]
      @context[:annotation_scope_stack] ||= [@top_level_scope]
      @scope_stack = @context[:annotation_scope_stack]
    end

    def reset_to(pos)
      @lexer.reset_to(pos)
      @generator = to_enum(:each_token)
      @current = get_next
    end

    def advance
      @generator.next
    rescue StopIteration
      @top_level_scope.type_sigil = type_sigil
      [nil, ['$eof']]
    end

    private

    def type_sigil
      @lexer.comments.each do |comment|
        if comment.text =~ /\A#\s+typed:\s+(ignore|false|true|strict|strong)\z/
          return Regexp.last_match.captures[0]
        end
      end

      nil
    end

    def current
      @current
    end

    def current_scope
      @scope_stack.last
    end

    def push_scope(scope)
      @scope_stack.push(scope)
    end

    def pop_scope
      @scope_stack.pop
    end

    def each_token(&block)
      loop do
        break unless type_of(current)

        handle_current(block)
      end
    end

    def handle_current(block)
      case type_of(current)
        when :kMODULE
          mod = handle_module(block)
          current_scope.scopes << mod
          push_scope(mod)
        when :kCLASS
          klass = handle_class(block)
          current_scope.scopes << klass
          push_scope(klass)
        when :kDEF
          mtd = handle_def(block)
          current_scope.methods << mtd
          push_scope(mtd)
        when :kEND
          pop_scope
          consume(:kEND, block)
        when :tIDENTIFIER
          ident = text_of(current)

          case ident
            when 'private', 'public'
              if ivar = maybe_handle_ivar(block)
                current_scope.ivars << ivar
              end
            when 'include', 'extend', 'prepend'
              consume(:tIDENTIFIER, block)
              const = handle_constant(block)
              current_scope.mixins << [ident.to_sym, const]
            else
              consume(type_of(current), block)
          end

        else
          consume(type_of(current), block)
      end
    end

    def maybe_handle_ivar(block)
      modifiers = [current]
      consume(:tIDENTIFIER)

      while type_of(current) == :tIDENTIFIER
        modifiers << current
        consume(:tIDENTIFIER)
      end

      if type_of(current) != :tIVAR
        modifiers.each { |mod| block.call(mod) }
        return nil
      end

      ivar_token = current
      name = text_of(current)
      consume(:tIVAR)
      consume(:tCOLON)
      type = handle_types

      modifiers.each do |modifier|
        case text_of(modifier)
          when 'attr_reader', 'attr_writer', 'attr_accessor'
            block.call(modifier)
        end
      end

      ivar = IVar.new(name, type, modifiers.map { |m| text_of(m) })

      if ivar.attr?
        block.call([:tSYMBOL, [ivar.bare_name, pos_of(ivar_token)]])
      end

      ivar.attrs.each do |attr|
        if attr.private?
          fabricate_and_yield(block, [
            [:tNL, nil],
            [:tIDENTIFIER, 'private'],
            [:tLPAREN2, '('],
            [:tSYMBOL, attr.method_str],
            [:tRPAREN, ')']
          ])
        end
      end

      ivar
    end

    def handle_class(block)
      consume(:kCLASS, block)
      class_type = handle_types
      yield_all(class_type.const.tokens, block)

      # The ruby lexer can get stuck lexing parameterized types, eg class MyClass[T]
      # and returns an EOF token when there is more input text to process. Resetting
      # fixes the problem.
      @lexer.reset_to(pos_of(current).begin_pos)
      @current = get_next

      super_type = if type_of(current) == :tLT
        consume(:tLT, block)
        handle_types.tap do |st|
          yield_all(st.const.tokens, block)
        end
      end

      ClassDef.new(class_type, super_type)
    end

    def handle_module(block)
      consume(:kMODULE, block)
      const = handle_constant(block)
      ModuleDef.new(const)
    end

    def handle_def(block)
      consume(:kDEF, block)
      method_name = text_of(current)
      consume(:tIDENTIFIER, block)
      args = []

      if type_of(current) == :tLPAREN2
        consume(:tLPAREN2, block)
        args = handle_args(block)
      end

      return_type = if type_of(current) == :tLAMBDA
        consume(:tLAMBDA)
        handle_types
      end

      MethodDef.new(method_name, Args.new(args), return_type)
    end

    def handle_args(block)
      [].tap do |args|
        loop do
          if type_of(current) == :tRPAREN
            consume(:tRPAREN, block)
            break
          end

          args << handle_arg(block)

          if type_of(current) == :tCOMMA
            consume(:tCOMMA, block)
          end
        end
      end
    end

    def handle_arg(block)
      block_arg = false

      if type_of(current) == :tAMPER
        block_arg = true
        consume(:tAMPER, block)
      end

      label = current
      arg_name = text_of(label)

      arg_type = case type_of(current)
        when :tLABEL
          consume(:tLABEL)
          block.call([:tIDENTIFIER, [arg_name, pos_of(label)]])
          handle_type
        when :tIDENTIFIER
          consume(:tIDENTIFIER, block)
          Type.new(:untyped)
        else
          Type.new(:untyped)
      end

      Arg.new(arg_name, arg_type, block_arg)
    end

    def handle_types
      if type_of(current) == :tLBRACK
        return handle_type_list
      end

      types = [].tap do |types|
        loop do
          types << handle_type

          if type_of(current) == :tPIPE
            consume(:tPIPE)
          else
            break
          end
        end
      end

      # TODO: handle intersection types as well, maybe joined with a + or & char?
      if types.size > 1
        UnionType.new(types)
      elsif types.size == 1
        types.first
      else
        Type.new(:untyped)
      end
    end

    def handle_type
      if type_of(current) == :kNIL
        consume(:kNIL)
        return nil
      end

      const = handle_constant
      return nil unless const

      type_args = []
      count = 0

      if type_of(current) == :tLBRACK2
        consume(:tLBRACK2)

        until type_of(current) == :tRBRACK
          if type_args.size > 0
            consume(:tCOMMA)
          end

          type_args << handle_types
        end

        consume(:tRBRACK)
      end

      Annotations.get_type(const, *type_args)
    end

    def handle_type_list
      consume(:tLBRACK)

      TypeList.new(
        [].tap do |type_list|
          until type_of(current) == :tRBRACK
            if type_list.size > 0
              consume(:tCOMMA)
            end

            type_list << handle_type
          end

          consume(:tRBRACK)
        end
      )
    end

    def handle_constant(block = nil)
      return nil unless const_token?(current)

      tokens = [].tap do |const_tokens|
        loop do
          if const_token?(current)
            const_tokens << current
            consume(type_of(current), block)
          else
            break
          end
        end
      end

      Constant.new(tokens)
    end

    def join(tokens)
      tokens.map { |t| text_of(t) }.join
    end

    def yield_all(tokens, block)
      tokens.each { |t| block.call(t) }
    end

    def fabricate_and_yield(block, tokens)
      tokens.each do |(type, text)|
        block.call([type, [text, make_range(0, 0)]])
      end
    end

    def const_token?(token)
      case type_of(token)
        when :tCONSTANT, :tCOLON2, :tCOLON3
          true
        else
          false
      end
    end

    def consume(types, block = nil)
      types = Array(types)

      if !types.include?(type_of(current))
        raise UnexpectedTokenError,
          "expected #{to_list(types.map(&:to_s))}, got #{type_of(current)} "\
          "on line #{pos_of(current).line}"
      end

      block.call(current) if block
      @current = get_next
    end

    def to_list(items)
      if items.size == 1
        items.first
      elsif items.size == 2
        items.join(' or ')
      else
        items[0..-2].join(', ') << ' or ' << items[-1]
      end
    end

    def type_of(token)
      token[0]
    end

    def text_of(token)
      token[1][0]
    end

    def pos_of(token)
      token[1][1]
    end

    def get_next
      @lexer.advance
    end

    def make_range(start, stop)
      ::Parser::Source::Range.new(@lexer.source_buffer, start, stop)
    end
  end
end