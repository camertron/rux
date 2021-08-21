module Rux
  # adapted from https://github.com/maccman/sourcemap/blob/b65550a30ae3216e2d9afa19dee3593c2282a1e3/lib/source_map/vlq.rb

  module VLQ
    VLQ_BASE_SHIFT = 5
    VLQ_BASE = 1 << VLQ_BASE_SHIFT
    VLQ_BASE_MASK = VLQ_BASE - 1
    VLQ_CONTINUATION_BIT = VLQ_BASE

    BASE64_DIGITS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.chars.freeze
    BASE64_VALUES = (0...64)
      .each_with_object({}) { |i, ret| ret[BASE64_DIGITS[i]] = i }
      .freeze

    class << self
      def encode(ary)
        ''.tap do |result|
          ary.each do |n|
            vlq = n < 0 ? ((-n) << 1) + 1 : n << 1

            loop do
              digit = vlq & VLQ_BASE_MASK
              vlq >>= VLQ_BASE_SHIFT
              digit |= VLQ_CONTINUATION_BIT if vlq > 0
              result << BASE64_DIGITS[digit]

              break unless vlq > 0
            end
          end
        end
      end

      def decode(str)
        [].tap do |result|
          chars = str.chars

          while chars.any?
            vlq = 0
            shift = 0
            continuation = true

            while continuation
              char = chars.shift
              raise ArgumentError unless char

              digit = BASE64_VALUES[char]
              continuation = false if (digit & VLQ_CONTINUATION_BIT) == 0
              digit &= VLQ_BASE_MASK
              vlq += digit << shift
              shift += VLQ_BASE_SHIFT
            end

            result << (vlq & 1 == 1 ? -(vlq >> 1) : vlq >> 1)
          end
        end
      end
    end
  end
end