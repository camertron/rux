require 'parser'

module Rux
  class RuxParser
    class UnexpectedTokenError < StandardError; end
    class TagMismatchError < StandardError; end

    class << self
      def parse_file(path)
        buffer = ::Parser::Source::Buffer.new(path).read
        lexer = ::Rux::Lexer.new(buffer)
        new(lexer).parse
      end

      def parse(buffer)
        # buffer = ::Parser::Source::Buffer.new('(source)', source: str)
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
          raise UnexpectedTokenError,
            'expected ruby code or the start of a rux tag but found '\
              "#{type_of(current)} instead"
        end
      end

      AST::ListNode.new(children)
    end

    private

    def ruby
      tokens = [].tap do |ruby_tokens|
        loop do
          type = type_of(current)

          if type.nil? || RuxLexer.state_table.include?(type_of(current))
            break
          end

          ruby_tokens << current
          consume(type_of(current))
        end
      end

      AST::RubyNode.new(tokens) unless tokens.empty?
    end

    def tag
      tag_pos = pos_of(current)
      consume(:tRUX_TAG_OPEN_START)
      tag_name = text_of(current)
      consume(:tRUX_TAG_OPEN, :tRUX_TAG_SELF_CLOSING)
      maybe_consume(:tRUX_ATTRIBUTE_SPACES)
      attrs = attributes
      maybe_consume(:tRUX_ATTRIBUTE_SPACES)
      maybe_consume(:tRUX_TAG_OPEN_END)
      tag_node = AST::TagNode.new(tag_name, attrs, tag_pos)

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
      [].tap do |attrs|
        while is?(:tRUX_ATTRIBUTE_NAME)
          attrs << attribute
          maybe_consume(:tRUX_ATTRIBUTE_SPACES)
        end
      end
    end

    def attribute
      maybe_consume(:tRUX_ATTRIBUTE_SPACES)
      attr_name = text_of(current)
      attr_pos = pos_of(current)
      consume(:tRUX_ATTRIBUTE_NAME)
      maybe_consume(:tRUX_ATTRIBUTE_EQUALS_SPACES)

      attr_value = if maybe_consume(:tRUX_ATTRIBUTE_EQUALS)
        maybe_consume(:tRUX_ATTRIBUTE_VALUE_SPACES)
        attribute_value
      else
        # if no equals sign, assume boolean attribute
        AST::StringNode.new("\"true\"", nil)
      end

      AST::AttrNode.new(attr_name, attr_value, attr_pos)
    end

    def attribute_value
      if is?(:tRUX_ATTRIBUTE_VALUE_RUBY_CODE_START)
        attr_ruby_code
      else
        AST::StringNode.new(text_of(current), pos_of(current)).tap do
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
        pos = pos_of(current)
        consume(:tRUX_LITERAL)
        AST::TextNode.new(lit, pos) unless lit.empty?
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
