require 'parser/current'
require 'unparser'
require 'json'

module Rux
  class File
    attr_reader :path, :visitor

    def initialize(path, visitor: Rux.default_visitor)
      @path = path
      @visitor = visitor
    end

    def to_ruby(pretty: true, raise_on_missing_imports: true)
      ruby_code = visitor.visit(parse_result.ast)
      ast, comments = ::Parser::CurrentRuby.parse_with_comments(ruby_code)
      rewriter = Imports::ImportRewriter.new(
        parse_result.context[:imports],
        raise_on_missing_imports: raise_on_missing_imports
      )
      ast = rewriter.process(ast)
      ::Unparser.unparse(ast, comments)
    end

    def write(outfile = nil, **kwargs)
      ruby_code, source_map = to_ruby(**kwargs)
      ruby_file = outfile || default_outfile
      source_map_file = ruby_file.chomp(::File.extname(ruby_file)) + '.map'

      ::File.write(ruby_file, ruby_code)
      ::File.write(source_map_file, source_map.to_sourcemap.to_json)
    end

    def default_outfile
      @default_outfile ||= "#{path.chomp('.rux')}.rb"
    end

    private

    def parse_result
      @parse_result ||= Parser.parse(contents)
    end

    def contents
      @contents ||= ::File.read(path)
    end
  end
end
