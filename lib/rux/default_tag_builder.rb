module Rux
  class DefaultTagBuilder
    def call(tag_name, attributes = {}, &block)
      SafeString.new(build(tag_name, attributes, &block))
    end

    private

    def build(tag_name, attributes = {})
      attr_str = attributes.empty? ? '' : " #{serialize_attrs(attributes)}"

      "<#{tag_name}#{attr_str}>".tap do |result|
        if block_given?
          Array(yield).each { |body| result << body }
        end

        result << "</#{tag_name}>"
      end
    end

    def serialize_attrs(attributes)
      ''.tap do |result|
        attributes.each_pair.with_index do |(k, v), idx|
          result << ' ' unless idx == 0
          result << "#{k}=\"#{v.to_s.gsub('"', "&quot;")}\""
        end
      end
    end
  end
end
