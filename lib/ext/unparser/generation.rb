module Rux
  module UnparserGenerationPatch
    private

    def write_loc(strings, old_location, new_location = nil)
      locs = Array(strings).map(&buffer.method(:append))
      return unless callback

      if old_location
        new_location ||= locs.first.first...locs.last.last
        callback.call(buffer, old_location, new_location)
      end
    end

    def k_end
      buffer.indent
      emit_comments_before(:end)
      buffer.unindent
      write_loc('end', node.location.end.to_range)
    end

    def parentheses(open = '(', close = ')')
      begin_loc = node.location.respond_to?(:begin) ? node.location.begin&.to_range : nil
      end_loc = node.location.respond_to?(:end) ? node.location.end&.to_range : nil
      write_loc(open, begin_loc)
      yield
      write_loc(close, end_loc)
    end
  end
end


module Unparser
  module Generation
    prepend Rux::UnparserGenerationPatch
  end
end
