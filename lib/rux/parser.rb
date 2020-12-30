module Rux
  class Parser
    class UnexpectedTokenError < StandardError; end

    class << self
      def parse_file(path)
        buffer = ::Parser::Source::Buffer.new(path).read
        lexer = ::Rux::Lexer.new(buffer)
        new(lexer).parse
      end

      def parse(str)
        buffer = ::Parser::Source::Buffer.new('(source)', source: str)
        lexer = ::Rux::Lexer.new(buffer)
        new(lexer).parse
      end
    end

    def initialize(lexer)
      @lexer = lexer
      @stack = []
      @current = get_next
    end

    def parse
      curlies = 1
      children = []

      loop do
        type = type_of(current)
        break unless type

        case type
          when :tLCURLY, :tLBRACE, :tRUX_LITERAL_RUBY_CODE_START
            curlies += 1
          when :tRCURLY, :tRBRACE, :tRUX_LITERAL_RUBY_CODE_END
            curlies -= 1
        end

        break if curlies == 0

        if rb = ruby
          children << rb
        elsif type_of(current) == :tRUX_TAG_OPEN_START
          children << tag
        else
          binding.pry
        end
      end

      AST::ListNode.new(children)
    end

    # def parse
    #   @current = get_next
    #   ruby_start = 0
    #   ruby_stop = nil

    #   [].tap do |result|
    #     while token_type = type_of(current)
    #       case token_type
    #         when :tRUX_TAG_OPEN_START
    #           if ruby_stop && ruby_start < ruby_stop
    #             ruby_code = @lexer.source_buffer.source[ruby_start...ruby_stop]
    #             result << AST::RubyNode.new(ruby_code)
    #           end

    #           result << tag
    #           ruby_start = ruby_stop = pos_of(current).end_pos
    #         else
    #           ruby_stop = pos_of(current).end_pos
    #           consume(token_type)
    #       end
    #     end

    #     if ruby_stop && ruby_start < ruby_stop
    #       ruby_code = @lexer.source_buffer.source[ruby_start...ruby_stop]
    #       result << AST::RubyNode.new(ruby_code)
    #     end
    #   end
    # end

    private

    def ruby
      ruby_start = pos_of(current).begin_pos

      loop do
        type = type_of(current)

        if type.nil? || RuxLexer.state_table.include?(type_of(current))
          break
        end

        consume(type_of(current))
      end

      unless type_of(current)
        return AST::RubyNode.new(
          @lexer.source_buffer.source[ruby_start..-1]
        )
      end

      if pos_of(current).begin_pos != ruby_start
        AST::RubyNode.new(
          @lexer.source_buffer.source[ruby_start...(pos_of(current).end_pos - 1)]
        )
      end
    end

    def tag
      consume(:tRUX_TAG_OPEN_START)
      tag_name = text_of(current)
      consume(:tRUX_TAG_OPEN, :tRUX_TAG_SELF_CLOSING)
      attrs = attributes
      maybe_consume(:tRUX_ATTRIBUTE_SPACES)
      consume(:tRUX_TAG_OPEN_END)
      tag_node = AST::TagNode.new(tag_name, attrs)

      if is?(:tRUX_TAG_SELF_CLOSING_END)
        consume(:tRUX_TAG_SELF_CLOSING_END)
        return tag_node
      end

      @stack.push(tag_name)

      until is?(:tRUX_TAG_CLOSE_START)
        if is?(:tRUX_LITERAL, :tRUX_LITERAL_RUBY_CODE_START)
          lit = literal
          tag_node.children << lit if lit
        else
          tag_node.children << tag
        end
      end

      consume(:tRUX_TAG_CLOSE_START)
      # @TODO: check open/close tags match
      @stack.pop
      consume(:tRUX_TAG_CLOSE)
      consume(:tRUX_TAG_CLOSE_END)

      tag_node
    end

    def attributes
      {}.tap do |attrs|
        while is?(:tRUX_ATTRIBUTE_SPACES, :tRUX_ATTRIBUTE_NAME)
          key, value = attribute
          attrs[key] = value
        end
      end
    end

    def attribute
      maybe_consume(:tRUX_ATTRIBUTE_SPACES)
      attr_name = text_of(current)
      consume(:tRUX_ATTRIBUTE_NAME)
      maybe_consume(:tRUX_ATTRIBUTE_EQUALS_SPACES)
      consume(:tRUX_ATTRIBUTE_EQUALS)
      maybe_consume(:tRUX_ATTRIBUTE_VALUE_SPACES)
      attr_value = attribute_value
      [attr_name, attr_value]
    end

    def attribute_value
      if is?(:tRUX_ATTRIBUTE_VALUE_RUBY_CODE_START)
        attr_ruby_code
      else
        AST::StringNode.new(text_of(current)).tap do
          consume(:tRUX_ATTRIBUTE_VALUE)
        end
      end
    end

    def attr_ruby_code
      consume(:tRUX_ATTRIBUTE_VALUE_RUBY_CODE_START)

      ruby.tap do
        consume(:tRUX_ATTRIBUTE_VALUE_RUBY_CODE_END)
      end
    end

    def literal
      if is?(:tRUX_LITERAL_RUBY_CODE_START)
        literal_ruby_code
      else
        lit = text_of(current)
        consume(:tRUX_LITERAL)
        AST::TextNode.new(lit.squeeze(' ')) unless lit.strip.empty?
      end
    end

    def literal_ruby_code
      consume(:tRUX_LITERAL_RUBY_CODE_START)

      parse.tap do |res|
        consume(:tRUX_LITERAL_RUBY_CODE_END)
      end
    end

    def current
      @current
    end

    def is?(*types)
      types.include?(type_of(current))
    end

    def maybe_consume(type)
      if type_of(current) == type
        @current = get_next
      end
    end

    def consume(*types)
      if !types.include?(type_of(current))
        raise UnexpectedTokenError,
          "expected [#{types.map(&:to_s).join(', ')}], got '#{type_of(current)}'"
      end

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
