require 'stringio'

# Racc uses LoadErrors for flow control and in certain ruby versions will
# print one along with its stack trace when required. To avoid receiving a
# long, arresting, and entirely irrelevant stack trace every time you invoke
# rux, temporarily redirect STDOUT here and throw away the output.
begin
  old_stdout = $stdout
  $stdout = StringIO.new
  require 'racc/parser'
ensure
  $stdout = old_stdout
end

require 'cgi'
require 'parser/current'
require 'unparser'

module Rux
  autoload :AST,               'rux/ast'
  autoload :BaseLexer,         'rux/base_lexer'
  autoload :Buffer,            'rux/buffer'
  autoload :Component,         'rux/component'
  autoload :DefaultTagBuilder, 'rux/default_tag_builder'
  autoload :DefaultVisitor,    'rux/default_visitor'
  autoload :File,              'rux/file'
  autoload :ImportLexer,       'rux/import_lexer'
  autoload :Imports,           'rux/imports'
  autoload :Lex,               'rux/lex'
  autoload :Lexer,             'rux/lexer'
  autoload :Parser,            'rux/parser'
  autoload :RubyLexer,         'rux/ruby_lexer'
  autoload :RuxLexer,          'rux/rux_lexer'
  autoload :StateBasedLexer,   'rux/state_based_lexer'
  autoload :StateMachine,      'rux/state_machine'
  autoload :StateTable,        'rux/state_table'
  autoload :TokenMatcher,      'rux/token_matcher'
  autoload :Utils,             'rux/utils'
  autoload :Visitor,           'rux/visitor'

  class << self
    attr_accessor :tag_builder, :buffer

    def to_ruby(str, visitor: default_visitor, pretty: true, raise_on_missing_imports: true)
      parse_result = Parser.parse(str)
      ruby_code = visitor.visit(parse_result.ast)
      ast, comments = ::Parser::CurrentRuby.parse_with_comments(ruby_code)
      rewriter = Imports::ImportRewriter.new(
        parse_result.context[:imports],
        raise_on_missing_imports: raise_on_missing_imports
      )
      ast = rewriter.process(ast)
      ::Unparser.unparse(ast, comments)
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

# unfortunately these have to be set globally :(
Parser::Builders::Default.tap do |builder|
  builder.emit_lambda              = true
  builder.emit_procarg0            = true
  builder.emit_encoding            = true
  builder.emit_index               = true
  builder.emit_arg_inside_procarg0 = true
  builder.emit_forward_arg         = true
  builder.emit_kwargs              = true
  builder.emit_match_pattern       = true
end
