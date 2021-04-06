require 'parser/current'
require 'unparser'

module Rux
  class File
    attr_reader :path, :visitor

    def initialize(path, visitor: Rux.default_visitor)
      @path = path
      @visitor = visitor
    end

    def to_ruby(pretty: true)
      ruby_code = visitor.visit(parse_result.ast)
      return ruby_code unless pretty

      ::Unparser.unparse(
        *::Parser::CurrentRuby.parse_with_comments(ruby_code)
      )
    end

    def to_rbi
      parse_result.context[:annotations].to_rbi
    end

    def write(outfile = nil, **kwargs)
      ::File.write(outfile || default_outfile, to_ruby(**kwargs))
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
