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
      ::File.write(outfile || default_outfile, to_ruby(**kwargs))
    end

    def default_outfile
      @outfile ||= "#{path.chomp('.rux')}.ruxc"
    end

    private

    def contents
      @contents ||= ::File.read(path)
    end
  end
end
