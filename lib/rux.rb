require 'cgi'
require 'parser/current'
require 'unparser'

module Rux
  autoload :AnnotationLexer,   'rux/annotation_lexer'
  autoload :AST,               'rux/ast'
  autoload :BaseLexer,         'rux/base_lexer'
  autoload :Buffer,            'rux/buffer'
  autoload :Component,         'rux/component'
  autoload :DefaultTagBuilder, 'rux/default_tag_builder'
  autoload :DefaultVisitor,    'rux/default_visitor'
  autoload :File,              'rux/file'
  autoload :ImportLexer,       'rux/import_lexer'
  autoload :Lex,               'rux/lex'
  autoload :Lexer,             'rux/lexer'
  autoload :Parser,            'rux/parser'
  autoload :RubyLexer,         'rux/ruby_lexer'
  autoload :RuxLexer,          'rux/rux_lexer'
  autoload :StateBasedLexer,   'rux/state_based_lexer'
  autoload :StateMachine,      'rux/state_machine'
  autoload :StateTable,        'rux/state_table'
  autoload :Utils,             'rux/utils'
  autoload :Visitor,           'rux/visitor'

  class << self
    attr_accessor :tag_builder, :buffer

    def to_ruby(str, visitor: default_visitor, pretty: true)
      ruby_code = visitor.visit(Parser.parse(str))
      return ruby_code unless pretty

      ::Unparser.unparse(
        ::Parser::CurrentRuby.parse(ruby_code)
      )
    end

    def default_visitor
      @default_visitor ||= DefaultVisitor.new
    end

    def default_tag_builder
      @default_tag_builder ||= DefaultTagBuilder.new
    end

    def default_buffer
      @default_buffer ||= Buffer
    end

    def tag(tag_name, attributes = {}, &block)
      tag_builder.call(tag_name, attributes, &block)
    end

    def create_buffer
      buffer.new
    end

    def library_paths
      @library_paths ||= []
    end
  end

  self.tag_builder = self.default_tag_builder
  self.buffer = self.default_buffer
end
