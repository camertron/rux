module Rux
  module Lex
    class DefaultPattern
      def matches?(_)
        true
      end
    end

    class CharsetPattern
      def self.parse(str)
        pairs = str.scan(/(.)-?(.)?/)

        new(
          pairs.flat_map do |pair|
            if pair[1]
              (pair[0]..pair[1]).to_a
            else
              [pair[0]]
            end
          end
        )
      end

      attr_reader :chars

      def initialize(chars)
        @chars = Set.new(chars)
      end

      def matches?(char)
        chars.include?(char)
      end
    end

    class NegatedCharsetPattern < CharsetPattern
      def matches?(char)
        !chars.include?(char)
      end
    end

    class EofPattern
      def matches?(eof_sym)
        eof_sym == :eof
      end
    end
  end
end
