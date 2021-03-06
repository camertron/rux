module Rux
  class AnnotationLexer
    class Scope
      attr_reader :name, :methods, :scopes, :includes, :extends, :prepends

      def initialize(name)
        @name = name
        @methods = []
        @scopes = []
        @includes = []
        @extends = []
        @prepends = []
      end
    end

    class TopLevelScope < Scope
      def initialize
        super('(toplevel)')
      end
    end

    class ModuleDef < Scope
    end

    class ClassDef < Scope
      attr_reader :type, :super_type

      def initialize(name, type, super_type)
        super(name)
        @type = type
        @super_type = super_type
      end
    end

    class MethodDef < Scope
      attr_reader :name, :args, :return_type

      def initialize(name, args, return_type)
        @args = args
        @return_type = return_type
        super(name)
      end
    end

    class Arg
      attr_reader :name, :type

      def initialize(name, type)
        @name = name
        @type = type
      end
    end

    class Type
      def initialize(const, subtypes = [])
        @const = const
        @subtypes = subtypes
      end
    end

    class UnionType
      def initialize(types)
        @types = types
      end
    end

    class UnexpectedTokenError < StandardError; end

    attr_reader :source_buffer

    def initialize(source_buffer, init_pos)
      @source_buffer = source_buffer
      @lexer = RubyLexer.new(source_buffer, init_pos)
      @generator = to_enum(:each_token)
      @current = get_next
      @scope_stack = [TopLevelScope.new]
    end

    def method_missing(method_name, *args, **kwargs, &block)
      @lexer.send(method_name, *args, **kwargs, &block)
    end

    def advance
      @generator.next
    rescue StopIteration
      [nil, ['$eof']]
    end

    private

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
            consume(:tIDENTIFIER, block)
            const = text_of(current)

            case ident
              when 'include'
                current_scope.includes << const
                consume(:tCONSTANT, block)
              when 'extend'
                current_scope.extends << const
                consume(:tCONSTANT, block)
              when 'prepend'
                current_scope.prepends << const
                consume(:tCONSTANT, block)
            end
          else
            consume(type_of(current), block)
        end
      end
    end

    def handle_class(block)
      consume(:kCLASS, block)
      const = current
      block.call(const)
      class_type = handle_types

      # The ruby lexer can get stuck lexing parameterized types, eg class MyClass[T]
      # and returns an EOF token when there is more input text to process. Resetting
      # fixes the problem.
      @lexer.reset_to(pos_of(current).begin_pos)
      @current = get_next

      super_type = if type_of(current) == :tLT
        consume(:tLT, block)
        block.call(current)
        handle_types
      end

      ClassDef.new(text_of(const), class_type, super_type)
    end

    def handle_module(block)
      consume(:kMODULE, block)
      name = text_of(current)
      consume(:tCONSTANT)
      ModuleDef.new(name)
    end

    def handle_def(block)
      consume(:kDEF, block)
      method_name = text_of(current)
      consume(:tIDENTIFIER, block)
      consume(:tLPAREN2, block)
      args = handle_args(block)

      return_type = if type_of(current) == :tLAMBDA
        consume(:tLAMBDA)
        handle_types
      else
        Type.new(:untyped)
      end

      MethodDef.new(method_name, args, return_type)
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
      label = current
      arg_name = text_of(label)

      arg_type = if type_of(current) == :tLABEL
        consume(:tLABEL)
        block.call([:tIDENTIFIER, [arg_name, pos_of(label)]])
        handle_type
      else
        Type.new(:untyped)
      end

      Arg.new(arg_name, arg_type)
    end

    def handle_types
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
      const = text_of(current)
      consume(:tCONSTANT)
      subtypes = []

      if type_of(current) == :tLBRACK2
        consume(:tLBRACK2)

        until type_of(current) == :tRBRACK
          subtypes << handle_types
        end

        consume(:tRBRACK)
      end

      Type.new(const, subtypes)
    end

    def consume(types, block = nil)
      types = Array(types)

      if !types.include?(type_of(current))
        raise UnexpectedTokenError,
          "expected [#{types.map(&:to_s).join(', ')}], got '#{type_of(current)}'"
      end

      block.call(current) if block
      @current = get_next
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
  end
end