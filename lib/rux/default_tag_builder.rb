module Rux
  class DefaultTagBuilder
    def call(tag_name, attributes = {})
      attr_str = attributes.empty? ? '' : " #{serialize_attrs(attributes)}"
      "<#{tag_name}#{attr_str}>" <<
        (block_given? ? Array(yield) : []).join <<
        "</#{tag_name}>"
    end

    private

    def serialize_attrs(attributes)
      ''.tap do |result|
        attributes.each_pair.with_index do |(k, v), idx|
          result << ' ' unless idx == 0
          result << "#{k.to_s}=\"#{CGI.escape_html(v.to_s)}\""
        end
      end
    end
  end
end
