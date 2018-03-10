# frozen_string_literal: true

require_relative 'helper'

class RadixPackTest < Twenty48Test
  include Twenty48::RadixPack

  def test_radix_pack_nybbles
    # 0123_6 => 3 * 1 + 2 * 6 + 1 * 6**2
    assert_equal 3 + 12 + 36, radix_pack_nybbles(0x123, 6)

    # 0123_11 => 3 * 1 + 2 * 11 + 1 * 11**2
    assert_equal 3 + 22 + 121, radix_pack_nybbles(0x123, 11)
  end

  def round_trip(nybbles, max_exponent)
    packed = radix_pack_nybbles(nybbles, max_exponent)
    new_nybbles = radix_unpack_nybbles(packed, max_exponent)
    assert_equal nybbles, new_nybbles
  end

  def test_round_trip
    round_trip 0x0123, 6
    round_trip 0x0123, 11
    round_trip 0x0000000000000001, 4
    round_trip 0x1000000000000000, 4
    round_trip 0x5555555555555555, 6
  end
end
