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
  autoload :Annotations,       'rux/annotations'
  autoload :AnnotationLexer,   'rux/annotation_lexer'
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
  autoload :LexerInterface,    'rux/lexer_interface'
  autoload :RubyLexer,         'rux/ruby_lexer'
  autoload :RubyParser,        'rux/ruby_parser'
  autoload :RuxLexer,          'rux/rux_lexer'
  autoload :RuxParser,         'rux/rux_parser'
  autoload :RubyUnparser,      'rux/ruby_unparser'
  autoload :SourceMap,         'rux/source_map'
  autoload :StateBasedLexer,   'rux/state_based_lexer'
  autoload :StateMachine,      'rux/state_machine'
  autoload :StateTable,        'rux/state_table'
  autoload :TokenLexer,        'rux/token_lexer'
  autoload :TokenMatcher,      'rux/token_matcher'
  autoload :Utils,             'rux/utils'
  autoload :Visitor,           'rux/visitor'
  autoload :VLQ,               'rux/vlq'

  class << self
    attr_accessor :tag_builder, :buffer

    def to_ruby(str, visitor: default_visitor)
      buffer = ::Parser::Source::Buffer.new('(source)', source: str)
      rux_ast, context = RuxParser.parse(buffer)
      token_lexer = TokenLexer.new(rux_ast, buffer, visitor)
      parser = RubyParser.new(token_lexer)
      ruby_ast, comments = parser.parse(buffer)
      rewriter = Imports::ImportRewriter.new(
        buffer, context[:imports]
      )
      ruby_ast = rewriter.process(ruby_ast)
      ruby_code, source_map = RubyUnparser.unparse(ruby_ast, comments, buffer)
      context.merge!(source_map: source_map)
      [ruby_code, context]
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

    def default_annotations_path
      @default_annotations_path ||= './sorbet/rbi'
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
