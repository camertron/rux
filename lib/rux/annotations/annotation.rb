module Rux
  module Annotations
    class Annotation
      INDENT_WIDTH = 2  # spaces

      private

      def indent(str, level)
        indent_chars = " " * (level * INDENT_WIDTH)

        str
          .split(/(\r?\n)/)
          .map do |line|
            if line =~ /\A\r?\n\z/
              line
            else
              "#{indent_chars}#{line}"
            end
          end
          .join
      end

      def sym_quote(str)
        if str =~ /\A[^\d][\w\d]*\z/
          str
        else
          "'#{str.gsub("'", '\\\'')}'"
        end
      end

      def sym_join(key, value)
        "#{sym_quote(key)}: #{value}"
      end

      def sym(str)
        ":#{sym_quote(str)}"
      end
    end
  end
end
