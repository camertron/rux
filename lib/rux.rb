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
  autoload :Buffer,            'rux/buffer'
  autoload :Component,         'rux/component'
  autoload :DefaultTagBuilder, 'rux/default_tag_builder'
  autoload :DefaultVisitor,    'rux/default_visitor'
  autoload :File,              'rux/file'
  autoload :Lex,               'rux/lex'
  autoload :Lexer,             'rux/lexer'
  autoload :LexerInterface,    'rux/lexer_interface'
  autoload :RubyLexer,         'rux/ruby_lexer'
  autoload :RuxLexer,          'rux/rux_lexer'
  autoload :RuxParser,         'rux/rux_parser'
  autoload :Emitter,           'rux/emitter'
  autoload :Utils,             'rux/utils'
  autoload :Visitor,           'rux/visitor'
  autoload :VisitContext,      'rux/visit_context'

  class << self
    attr_accessor :tag_builder, :buffer

    def to_ruby(str, visitor: default_visitor, pretty: true)
      buffer = ::Parser::Source::Buffer.new('(source)', source: str)
      rux_ast = RuxParser.parse(buffer)
      emitter = Emitter.new(rux_ast, buffer, visitor)
      parser = ::Parser::CurrentRuby.new
      parser.diagnostics.all_errors_are_fatal = true
      parser.instance_variable_set(:@lexer, emitter)
      emitter.diagnostics = parser.diagnostics
      emitter.static_env  = parser.static_env
      emitter.context     = parser.context
      ast = parser.parse(buffer)
      puts Unparser.unparse(ast)

      # rux_ast = RuxParser.parse(str)
      # context = VisitContext.new(-> (token) { puts "#{token[0]}: #{token[1][0]}" })
      # visitor.visit(ast, context)

      # buffer = ::Parser::Source::Buffer.new('(source)', source: str)
      # lexer = ::Rux::Lexer.new(buffer)
      # parser = ::Parser::CurrentRuby.new
      # parser.instance_variable_set(:@lexer, lexer)
      # lexer.diagnostics = parser.diagnostics
      # lexer.static_env  = parser.static_env
      # lexer.context     = parser.context
      # ast = parser.parse(buffer)
      # ::Unparser.unparse(ast)

      # ruby_code = visitor.visit(Parser.parse(str))
      # return ruby_code unless pretty

      # ::Unparser.unparse(
      #   ::Parser::CurrentRuby.parse(ruby_code)
      # )
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
