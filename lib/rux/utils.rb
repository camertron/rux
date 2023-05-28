module Rux
  module Utils
    def attr_to_hash_elem(key, value, slugify: true)
      key = key.gsub('-', '_') if slugify

      if key =~ /\A[\w\d]+\z/
        "#{key}: #{value}"
      else
        ":\"#{key}\" => #{value}"
      end
    end
  end

  Utils.extend(Utils)
end
