# frozen_string_literal: true

require_relative 'helper'

class StateHashTableTest < Twenty48Test
  include Twenty48

  def test_pack_and_unpack
    table = StateHashTable.new(board_size: 2, size: 8)
    state = State.new([0, 1, 2, 3])
    packed = table.pack(state)
    # 1 + 0 + 1 * 11 + 2 * 11**2 + 3 * 11**3 = 4247 = 0x1097
    assert_equal "\x97\x10\x00\x00\x00\x00\x00\x00".b, packed
    assert_equal state, table.unpack(packed)
  end

  def test_insertion
    table = StateHashTable.new(board_size: 2, size: 6)

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
    refute table.member?(states[0])
    table.insert(states[0])
    assert table.member?(states[0])
    assert_equal 1, table.count

    # Should not insert duplicate state.
    table.insert(states[0])
    assert table.member?(states[0])
    assert_equal 1, table.count

    # Insert states to fill table.
    count = 1
    states.drop(1).take(5).each do |state|
      refute table.member?(state)
      table.insert(state)
      assert table.member?(state)
      count += 1
      assert_equal count, table.count
    end
    assert_equal 1, table.fill_factor

    # Can't insert into full table if state is already present.
    # (We could allow this, but it makes things more complicated.)
    assert_raises do
      table.insert(states.first)
    end
    assert_equal 6, table.count

    # Can't insert new state into full table.
    assert_raises do
      table.insert(states.last)
    end
    assert_equal 6, table.count
  end
end

