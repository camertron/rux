module Rux
  module UnparserRootPatch
    include Unparser::Concord::Public.new(:buffer, :node, :comments, :callback)
  end
end


module Unparser
  class Emitter
    class Root < self
      prepend Rux::UnparserRootPatch

      class Public < self
        prepend Rux::UnparserRootPatch
      end
    end
  end
end
