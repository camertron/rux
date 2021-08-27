module Rux
  module UnparserBufferPatch
    def append(string)
      if @content[-1].eql?(Unparser::Buffer::NL)
        prefix
      end
      write(string)
    end

    def append_without_prefix(string)
      write(string)
    end

    def write(fragment)
      start_pos = @content.length
      @content << fragment
      start_pos...@content.length
    end

    def length
      @content.length
    end
  end
end


module Unparser
  class Buffer
    prepend Rux::UnparserBufferPatch
  end
end
