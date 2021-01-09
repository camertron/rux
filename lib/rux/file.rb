module Rux
  class File
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def to_ruby(visitor = Rux.default_visitor)
      Rux.to_ruby(contents, visitor)
    end

    def write(outfile = nil)
      ::File.write(outfile || default_outfile, to_ruby)
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
