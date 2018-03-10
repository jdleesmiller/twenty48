# frozen_string_literal: true

module Twenty48
  #
  # Instead of writing the number in base 16, interpret it in a lower base.
  # The result is harder to work with but numerically smaller.
  # This is mainly so we can fit states for the 4x4 game to 64 into a JavaScript
  # integer (maximum value 2**53 - 1).
  #
  module RadixPack
    module_function

    def radix_pack_nybbles(nybbles, max_exponent)
      exponent = 1
      (0...16).reduce(0) do |result, i|
        shift = 4 * i
        value = (nybbles & (0xf << shift)) >> shift
        result += exponent * value
        exponent *= max_exponent
        result
      end
    end

    def radix_unpack_nybbles(packed, max_exponent)
      nybbles = 0
      (0..16).each do |i|
        packed, value = packed.divmod(max_exponent)
        nybbles |= (value << 4 * i)
      end
      nybbles
    end
  end
end
