module Rux
  class Buffer
    def initialize(init_str = '')
      @string = init_str.dup
    end

    def <<(str)
      @string << (str || '')
    end

    def to_s
      @string
    end
  end
end
