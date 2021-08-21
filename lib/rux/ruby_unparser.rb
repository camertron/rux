require 'unparser'

module Rux
  class RubyUnparser
    class << self
      def unparse(ast, comments, orig_buffer)
        ruby_code, positions = do_unparse(ast, comments)
        gen_buffer = ::Parser::Source::Buffer.new('(gen)', source: ruby_code)
        source_map = build_source_map(positions, orig_buffer, gen_buffer)
        [ruby_code, source_map]
      end

      private

      def do_unparse(ast, comments)
        positions = []

        ruby_code = ::Unparser.unparse(ast, comments) do |_buffer, old_pos, new_pos|
          next if old_pos.begin == -1
          positions << [old_pos, new_pos]
        end

        [ruby_code, positions]
      end

      def build_source_map(positions, orig_buffer, gen_buffer)
        SourceMap.new.tap do |source_map|
          positions.each do |(old_pos, new_pos)|
            old_range = ::Parser::Source::Range.new(orig_buffer, old_pos.first, old_pos.last)
            new_range = ::Parser::Source::Range.new(gen_buffer, new_pos.first, new_pos.last)
            add_position(old_range, new_range, source_map)
          end
        end
      end

      def add_position(old_range, new_range, source_map)
        source_map.add(
          name: old_range.source,
          gen_line: new_range.line,
          gen_col: new_range.column,
          orig_line: old_range.line,
          orig_col: old_range.column
        )
      end
    end
  end
end