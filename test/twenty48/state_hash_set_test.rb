# frozen_string_literal: true

require_relative 'helper'

class StateHashSetTest < Twenty48Test
  include Twenty48

  def test_pack_and_unpack
    table = StateHashSet.new(board_size: 2, max_size: 8)
    state = State.new([0, 1, 2, 3])
    packed = table.pack(state)
    # 1 + 0 + 1 * 11 + 2 * 11**2 + 3 * 11**3 = 4247 = 0x1097
    assert_equal "\x97\x10\x00\x00\x00\x00\x00\x00".b, packed
    assert_equal state, table.unpack(packed)
  end

  def test_hash_set
    set = StateHashSet.new(board_size: 2, max_size: 6)

    states = [
      [0, 0, 0, 0],
      [0, 0, 0, 1],
      [0, 0, 1, 1],
      [0, 1, 1, 1],
      [1, 1, 1, 1],
      [1, 1, 1, 2],
      [1, 1, 2, 2]
    ].map { |array| make_state(array) }

    # Insert first state.
    refute set.member?(states[0])
    set << states[0]
    assert set.member?(states[0])
    assert_equal 1, set.size

    # Should not insert duplicate state.
    set << states[0]
    assert set.member?(states[0])
    assert_equal 1, set.size

    # Insert states to fill set.
    size = 1
    states.drop(1).take(5).each do |state|
      refute set.member?(state)
      set << state
      assert set.member?(state)
      size += 1
      assert_equal size, set.size
    end
    assert_equal 1, set.fill_factor

    # Can't insert into full set if state is already present.
    # (We could allow this, but it makes things more complicated.)
    assert_raises do
      set << states.first
    end
    assert_equal 6, set.size

    # Can't insert new state into full set.
    assert_raises do
      set << states.last
    end
    assert_equal 6, set.size
  end
end
