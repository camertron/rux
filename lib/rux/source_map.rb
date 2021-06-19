require 'json'

module Rux
  SourceMapping = Struct.new(
    :name, :gen_line, :gen_col, :orig_line, :orig_col
  )

  Group = Struct.new(:gen_col, :orig_file_id, :orig_line, :orig_col, :name_id) do
    def self.blank
      new(0, 0, 1, 0, 0)
    end

    def +(other)
      other_a = other.to_a

      self.class.new(
        *to_a.map.with_index do |field, idx|
          field + other_a[idx]
        end
      )
    end

    def -(other)
      other_a = other.to_a

      self.class.new(
        *to_a.map.with_index do |field, idx|
          field - other_a[idx]
        end
      )
    end
  end

  class SourceMapString
    attr_reader :name_list, :str, :last_group, :cur_line

    def initialize(name_list)
      @name_list = name_list
      @last_group = Group.blank
      @str = ''
      @cur_line = 1
    end

    def append(mapping)
      jumped_lines = mapping.gen_line - cur_line

      if jumped_lines > 0
        @last_group.gen_col = 0
        @str << ';' * jumped_lines
      end

      unless str.empty? || str.end_with?(';') || str.end_with?(',')
        @str << ','
      end

      group = group_for(mapping)
      @str << VLQ.encode((group - last_group).to_a)

      @last_group = group
      @cur_line = mapping.gen_line
    end

    def to_s
      str
    end

    private

    def group_for(mapping)
      Group.new(
        mapping.gen_col,
        0,
        mapping.orig_line,
        mapping.orig_col,
        name_list.index(mapping.name)
      )
    end

    def adjust_group(group, prev_group)
      group.map.with_index do |field, idx|
        field - prev_group[idx]
      end
    end
  end

  class SourceMap
    class << self
      def load_file(path)
        load(::File.read(path))
      end

      def load(json_str)
        data = JSON.parse(json_str)
        sources = data['sources']
        names = data['names']
        group = Group.blank

        new.tap do |map|
          data['mappings'].split(';').each_with_index do |line, line_no|
            line.split(',').each do |group_str|
              group += Group.new(*VLQ.decode(group_str))

              map.add(
                name: names[group[4]],
                gen_line: line_no + 1,
                gen_col: group[0],
                orig_line: group[2],
                orig_col: group[3]
              )
            end
          end
        end
      end
    end

    attr_reader :mappings, :orig_files, :names

    def initialize(mappings = [])
      @orig_files = Set.new
      @names = Set.new
      @mappings = []

      mappings.each { |mapping| add_mapping(mapping) }
    end

    def add(name:, gen_line:, gen_col:, orig_line:, orig_col:)
      add_mapping(
        SourceMapping.new(
          name, gen_line, gen_col, orig_line, orig_col
        )
      )
    end

    def add_mapping(mapping)
      names << mapping.name
      mappings << mapping
    end

    def to_sourcemap
      name_list = names.to_a
      serialized_mappings = serialize_mappings(name_list)

      {
        version: 3,
        names: name_list,
        mappings: serialized_mappings.to_s
      }
    end

    def serialize_mappings(name_list)
      SourceMapString.new(name_list).tap do |str|
        mappings.sort_by(&:gen_line).each do |mapping|
          str.append(mapping)
        end
      end
    end
  end
end
