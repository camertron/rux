module Rux
  module Utils
    def attr_to_hash_elem(key, value)
      if key =~ /\A[\w\d]+\z/
        "#{key}: #{value}"
      else
        ":\"#{key}\" => #{value}"
      end
    end
  end

  Utils.extend(Utils)
end
