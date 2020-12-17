module Rux
  class Parser
    class UnexpectedTokenError < StandardError; end

    def initialize(lexer)
      @lexer = lexer
      @stack = []
    end

    def parse
      @current = get_next
      ruby_start = 0
      ruby_stop = nil

      [].tap do |result|
        while token_type = type_of(current)
          case token_type
            when :tag_open_start
              if ruby_stop && ruby_start < ruby_stop
                ruby_code = @lexer.source_buffer.source[ruby_start...ruby_stop]
                result << AST::RubyNode.new(ruby_code)
              end

              result << tag
              ruby_start = ruby_stop = pos_of(current).end_pos
            else
              ruby_stop = pos_of(current).end_pos
              consume(token_type)
          end
        end

        if ruby_stop && ruby_start < ruby_stop
          ruby_code = @lexer.source_buffer.source[ruby_start...ruby_stop]
          result << AST::RubyNode.new(ruby_code)
        end
      end
    end

    private

    def tag
      consume(:tag_open_start)
      tag_name = text_of(current)
      consume(:tag_open, :tag_self_closing)
      attrs = attributes
      maybe_consume(:attribute_spaces)
      consume(:tag_open_end)
      tag_node = AST::TagNode.new(tag_name, attrs)

      if is?(:tag_self_closing_end)
        consume(:tag_self_closing_end)
        return tag_node
      end

      @stack.push(tag_name)

      until is?(:tag_close_start)
        if is?(:literal, :literal_ruby_code_start)
          lit = literal
          tag_node.children << lit if lit
        else
          tag_node.children << tag
        end
      end

      consume(:tag_close_start)
      # @TODO: check open/close tags match
      @stack.pop
      consume(:tag_close)
      consume(:tag_close_end)

      tag_node
    end

    def attributes
      {}.tap do |attrs|
        while is?(:attribute_spaces, :attribute_name)
          key, value = attribute
          attrs[key] = value
        end
      end
    end

    def attribute
      maybe_consume(:attribute_spaces)
      attr_name = text_of(current)
      consume(:attribute_name)
      maybe_consume(:attribute_equals_spaces)
      consume(:attribute_equals)
      maybe_consume(:attribute_value_spaces)
      attr_value = attribute_value
      [attr_name, attr_value]
    end

    def attribute_value
      if is?(:attribute_value_ruby_code_start)
        attr_ruby_code
      else
        AST::TextNode.new(text_of(current)).tap do
          consume(:attribute_value)
        end
      end
    end

    def attr_ruby_code
      consume(:attribute_value_ruby_code_start)

      AST::RubyNode.new(text_of(current)).tap do
        consume(:attribute_value_ruby_code)
        consume(:attribute_value_ruby_code_end)
      end
    end

    def literal
      if is?(:literal_ruby_code_start)
        literal_ruby_code
      else
        lit = text_of(current)
        consume(:literal)
        AST::TextNode.new(lit.squeeze(' ')) unless lit.strip.empty?
      end
    end

    def literal_ruby_code
      consume(:literal_ruby_code_start)

      AST::RubyNode.new(text_of(current)).tap do
        consume(:literal_ruby_code)
        consume(:literal_ruby_code_end)
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
      if @eof
        EOF_TOKEN
      else
        @lexer.advance
      end
    end
  end
end
