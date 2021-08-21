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

    def to_ruby(**kwargs)
      Rux.to_ruby(contents, **kwargs)
    end

    def default_outfile
      @default_outfile ||= "#{path.chomp('.rux')}.rb"
    end

    def default_sourcemap_file
      @default_sourcemap_file = "#{default_outfile.chomp('.rb')}.map"
    end

    private

    def contents
      @contents ||= ::File.read(path)
    end
  end
end
