require 'json'

module Rux
  class File
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def to_ruby(visitor: Rux.default_visitor, **kwargs)
      Rux.to_ruby(contents, visitor: visitor, **kwargs)
    end

    def write(outfile = nil, **kwargs)
      ruby_code, source_map = to_ruby(**kwargs)
      ruby_file = outfile || default_outfile
      source_map_file = ruby_file.chomp(::File.extname(ruby_file)) + '.map'

      ::File.write(ruby_file, ruby_code)
      ::File.write(source_map_file, source_map.to_sourcemap.to_json)
    end

    def default_outfile
      @outfile ||= "#{path.chomp('.rux')}.rb"
    end

    private

    def contents
      @contents ||= ::File.read(path)
    end
  end
end
