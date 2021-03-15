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
    end
  end
end
