module Rux
  module UnparserConcordPatch
    def initialize(*names)
      @names = names
      define_initialize
      define_readers
      define_equalizer
    end
  end
end


module Unparser
  class Concord < Module
    prepend Rux::UnparserConcordPatch
  end
end
