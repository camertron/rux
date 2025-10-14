module Rux
  class DefaultVisitorWithSourceMap < DefaultVisitor
    attr_reader :source_map

    def initialize(...)
      super

      @source_positions = []
    end

    def visit_root(root_node)
      super.tap do |code|
        mappings = []

        loop do
          code.index(/RUX_CODE_START\((\d+), (\d+)\)\|/)
          match = Regexp.last_match
          break unless match

          source_position_index, len = *match.captures.map(&:to_i)
          source_position = @source_positions[source_position_index]

          mappings << [
            source_position,
            match.begin(0),
            match.begin(0) + len
          ]

          code[match.begin(0)...match.end(0)] = ''
        end

        path = @options[:path] || "(source)"
        buffer = ::Parser::Source::Buffer.new(path, source: code)

        mappings.map! do |source_position, gen_start, gen_end|
          [source_position, ::Parser::Source::Range.new(buffer, gen_start, gen_end)]
        end

        @source_map = SourceMap.new(buffer, mappings)
      end
    end

    def visit_ruby(node)
      @source_positions << node.pos
      "RUX_CODE_START(#{@source_positions.size - 1}, #{node.code.size})|#{super}"
    end
  end
end
