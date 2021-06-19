module Rux
  module VLQ
    VLQ_BASE_SHIFT = 5
    VLQ_BASE = 1 << VLQ_BASE_SHIFT
    VLQ_BASE_MASK = VLQ_BASE - 1
    VLQ_CONTINUATION_BIT = VLQ_BASE

    BASE64_DIGITS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.split('')
    BASE64_VALUES = (0...64).inject({}) { |h, i| h[BASE64_DIGITS[i]] = i; h }

    class << self
      def encode(ary)
        result = []
        ary.each do |n|
          vlq = n < 0 ? ((-n) << 1) + 1 : n << 1
          loop do
            digit  = vlq & VLQ_BASE_MASK
            vlq  >>= VLQ_BASE_SHIFT
            digit |= VLQ_CONTINUATION_BIT if vlq > 0
            result << BASE64_DIGITS[digit]

            break unless vlq > 0
          end
        end
        result.join
      end

      def decode(str)
        result = []
        chars = str.split('')
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
            vlq   += digit << shift
            shift += VLQ_BASE_SHIFT
          end
          result << (vlq & 1 == 1 ? -(vlq >> 1) : vlq >> 1)
        end
        result
      end
    end
  end
end