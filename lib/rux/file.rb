module Rux
  class File
    attr_reader :path, :source_map

    def initialize(path)
      @path = path
    end

    def to_ruby(visitor: nil, underscore_attributes: true, **kwargs)
      visitor ||= DefaultVisitorWithSourceMap.new(
        underscore_attributes: underscore_attributes
      )

      Rux.to_ruby(contents, visitor: visitor, **kwargs).tap do
        @source_map = visitor.source_map if visitor.respond_to?(:source_map)
      end
    end

    def write(outfile = nil, **kwargs)
      ::File.write(outfile || default_outfile, to_ruby(**kwargs))
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
