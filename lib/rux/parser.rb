require 'parser'

module Rux
  class Parser
    class UnexpectedTokenError < StandardError; end
    class TagMismatchError < StandardError; end

    class ParseResult
      attr_reader :ast, :context

      def initialize(ast, context)
        @ast = ast
        @context = context
      end
    end

    class << self
      def parse_file(path)
        buffer = ::Parser::Source::Buffer.new(path).read
        lexer = ::Rux::Lexer.new(buffer)
        parser = new(lexer)
        ParseResult.new(parser.parse, lexer.context)
      end

      def parse(str)
        buffer = ::Parser::Source::Buffer.new('(source)', source: str)
        lexer = ::Rux::Lexer.new(buffer)
        parser = new(lexer)
        ParseResult.new(parser.parse, lexer.context)
      end
    end

    # TODO: handle comments
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
          raise UnexpectedTokenError,
            'expected ruby code or the start of a rux tag but found '\
              "#{type_of(current)} instead"
        end
      end

      AST::ListNode.new(children)
    end

    private

    def ruby
      result = ''.tap do |code|
        last_token = nil

        loop do
          type = type_of(current)
          break if type.nil? || RuxLexer.state_table.include?(type)

          if last_token
            # Extract white space from between the last two ruby tokens and emit it.
            # The between text may or may not be entirely whitespace. Tokens that are
            # removed during the lexing process (eg. annotations, etc) aren't yielded
            # to this parser, but are obviously still present in the original rux
            # source code. Slices of the input text can therefore contain any amount
            # of "throwaway" text. In such cases, the between text will also contain
            # trailing whitespace that is important to capture, so we extract it off
            # the end and emit it.
            between = @lexer.source_buffer.source[pos_of(last_token).end_pos...pos_of(current).begin_pos]
            code << (between[/\s+\z/] || '')
          end

          case type
            when :tNL
              code << "\n"
            when :kDO
              # special case since lexer seems to not emit newlines that
              # follow a "do"
              code << "do "
            else
              code << "#{text_of(current)}"
          end

          last_token = current
          consume(type_of(current))
        end
      end

      result.empty? ? nil : AST::RubyNode.new(result)
    end

    def tag
      consume(:tRUX_TAG_OPEN_START)
      tag_name = text_of(current)
      tag_pos = pos_of(current)
      consume(:tRUX_TAG_OPEN, :tRUX_TAG_SELF_CLOSING)
      maybe_consume(:tRUX_ATTRIBUTE_SPACES)
      attrs = attributes
      maybe_consume(:tRUX_ATTRIBUTE_SPACES)
      maybe_consume(:tRUX_TAG_OPEN_END)
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

      closing_tag_name = text_of(current)

      if @stack.last != closing_tag_name
        closing_tag_pos = pos_of(current)

        raise TagMismatchError, "closing tag '#{closing_tag_name}' on line "\
          "#{closing_tag_pos.line} did not match opening tag '#{tag_name}' "\
          "on line #{tag_pos.line}"
      end

      @stack.pop

      consume(:tRUX_TAG_CLOSE)
      consume(:tRUX_TAG_CLOSE_END)

      tag_node
    end

    def attributes
      {}.tap do |attrs|
        while is?(:tRUX_ATTRIBUTE_NAME)
          key, value = attribute
          attrs[key] = value

          maybe_consume(:tRUX_ATTRIBUTE_SPACES)
        end
      end
    end

    def attribute
      maybe_consume(:tRUX_ATTRIBUTE_SPACES)
      attr_name = text_of(current)
      consume(:tRUX_ATTRIBUTE_NAME)
      maybe_consume(:tRUX_ATTRIBUTE_EQUALS_SPACES)

      attr_value = if maybe_consume(:tRUX_ATTRIBUTE_EQUALS)
        maybe_consume(:tRUX_ATTRIBUTE_VALUE_SPACES)
        attribute_value
      else
        # if no equals sign, assume boolean attribute
        AST::StringNode.new("\"true\"")
      end

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
        lit = squeeze_lit(text_of(current))
        consume(:tRUX_LITERAL)
        AST::TextNode.new(lit) unless lit.empty?
      end
    end

    def squeeze_lit(lit)
      lit.gsub(/\s/, ' ').squeeze(' ')
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
        true
      else
        false
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
