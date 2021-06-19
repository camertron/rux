module Rux
  class Buffer
    def initialize(init_str = '')
      @string = init_str.dup
    end

    def <<(*obj)
      @string << obj.join
    end

    def to_s
      @string
    end
  end
end
