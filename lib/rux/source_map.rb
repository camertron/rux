module Rux
  class SourceMap
    attr_reader :mappings

    # mappings is an array of two-element arrays containing Parser::Source::Range objects.
    # The first range object is the source location and the second range object is the
    # generated location.
    def initialize(generated_buffer, mappings)
      @generated_buffer = generated_buffer
      @mappings = mappings
    end

    # search_position is a Ruby Range object denoting a range the generated source
    def source_position_for(start_line, start_col, end_line, end_col)
      begin_pos = offset_for_line_and_column(start_line, start_col) + 1
      end_pos = offset_for_line_and_column(end_line, end_col) + 1

      search_position = ::Parser::Source::Range.new(
        @generated_buffer,
        begin_pos,
        end_pos
      )

      source_position, generated_position = @mappings.bsearch do |_, generated_position|
        next 0 if generated_position.contains?(search_position)

        if search_position.begin_pos > generated_position.begin_pos
          1
        else
          -1
        end
      end

      return unless source_position && generated_position

      begin_delta = generated_position.begin_pos - begin_pos
      end_delta = end_pos - generated_position.end_pos

      source_position.adjust(begin_pos: begin_delta, end_pos: end_delta)
    end

    private

    def offset_for_line_and_column(line, column)
      offset = (1.upto(line - 1)).inject(0) do |sum, idx|
        sum + @generated_buffer.source_lines[idx - 1].size
      end

      offset + column
    end
  end
end
