require 'parser/current'
require 'unparser'

module Rux
  class Template
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def to_ruby
      ::Unparser.unparse(
        ::Parser::CurrentRuby.parse(root.to_ruby)
      )
    end

    def write(outfile = nil)
      File.write(outfile || default_outfile, to_ruby)
    end

    def default_outfile
      @outfile ||= "#{path.chomp('.rux')}.ruxc"
    end

    private

    def root
      @root ||= ::Rux::Parser.parse_file(path)
    end
  end
end
