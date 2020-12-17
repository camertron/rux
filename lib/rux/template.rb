module Rux
  class Template
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def to_ruby
      indent = 0

      ''.tap do |result|
        nodes.each do |node|
          case node.type
            when :ruby
              idx = node.code.rindex(/\r?\n\s+\z/)
              indent = node.code[idx..-1].sub(/\A[\r\n]+/, '').size / 2
              result << node.to_ruby
            when :tag
              result << node.to_ruby(indent)
              result << "\n"
            else
              result << node.to_ruby(indent)
          end
        end
      end
    end

    private

    def nodes
      @nodes ||= ::Rux::Parser.parse_file(path)
    end
  end
end
