module Rux
  class SafeString < String
    def html_safe?
      true
    end
  end

  class Buffer
    def initialize(init_str = '')
      @string = init_str.dup
    end

    def append(obj)
      Array(obj).each do |o|
        @string << if o.respond_to?(:html_safe?) && o.html_safe?
          o.to_s
        else
          CGI.escapeHTML(o.to_s)
        end
      end
    end

    def safe_append(obj)
      Array(obj).each { |o| @string << o.to_s }
    end

    def to_s
      SafeString.new(@string)
    end

    alias html_safe to_s
  end
end
