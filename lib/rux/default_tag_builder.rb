module Rux
  class DefaultTagBuilder
    def call(tag_name, attributes = {})
      "<#{tag_name} #{serialize_attrs(attributes)}>" <<
        (block_given? ? Array(yield) : []).join <<
        "</#{tag_name}>"
    end

    private

    def serialize_attrs(attributes)
      ''.tap do |result|
        attributes.each_pair.with_index do |(k, v), idx|
          result << ' ' unless idx == 0
          result << "#{k.to_s.gsub('-', '_')}=\"#{CGI.escape_html(v)}\""
        end
      end
    end
  end
end
