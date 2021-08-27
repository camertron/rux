module Rux
  module UnparserWriterSendPatch
    def emit_selector
      write_loc(details.string_selector, node.location.selector.to_range)
    end

    def emit_operator
      # annoyingly this is a private const
      operators = Unparser::Writer::Send.const_get(:OPERATORS)
      write_loc(operators.fetch(node.type), node.location.dot.to_range)
    end
  end
end


module Unparser
  module Writer
    class Send
      prepend Rux::UnparserWriterSendPatch
    end
  end
end

