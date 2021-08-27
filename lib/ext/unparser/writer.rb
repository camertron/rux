module Rux
  module UnparserWriterPatch
    include Unparser::Anima.new(:buffer, :comments, :node, :local_variable_scope, :callback)
  end
end


module Unparser
  module Writer
    prepend Rux::UnparserWriterPatch
  end
end
