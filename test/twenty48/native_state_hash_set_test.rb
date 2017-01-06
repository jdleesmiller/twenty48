# frozen_string_literal: true

require_relative 'helper'

class NativeStateHashSetTest < Twenty48NativeTest
  include Twenty48

  def test_hash_set_2
    set = StateHashSet2.new(6)

    # The lose state is implicitly included in the set.
    assert_equal 1, set.size
    lose_state = make_state([0, 0, 0, 0])
    assert set.member?(lose_state)

    states = [
      [0, 0, 0, 1],
      [0, 0, 1, 1],
      [0, 1, 1, 1],
      [1, 1, 1, 1],
      [1, 1, 1, 2],
      [1, 1, 2, 2]
    ].map { |array| make_state(array) }

    # Insert first state.
    refute set.member?(states[0])
    assert set << states[0]
    assert set.member?(states[0])
    assert_equal 2, set.size

    # Should not insert duplicate state.
    refute set << states[0]
    assert set.member?(states[0])
    assert_equal 2, set.size

    # Insert states to fill set.
    size = 2
    states.drop(1).take(4).each do |state|
      refute set.member?(state)
      assert set << state
      assert set.member?(state)
      size += 1
      assert_equal size, set.size
    end
    assert_equal 6, set.size
    assert_equal 1, set.fill_factor

    # Can't insert existing state into full set.
    assert_raises do
      set << states.first
    end
    assert_equal 6, set.size

    # Can't insert new state into full set.
    assert_raises do
      set << states.last
    end
    assert_equal 6, set.size

    assert_equal ([lose_state] + states.take(5)).sort, set.to_a.sort
  end

  def test_state_hash_set_dump_hex_2
    set = StateHashSet2.new(10)
    set.insert(make_state([0, 0, 0, 1]))
    set.insert(make_state([0, 0, 1, 1]))
    Dir.mktmpdir do |dir|
      pathname = File.join(dir, 'set.hex')
      set.dump_hex(pathname)
      result = File.readlines(pathname).sort.map(&:chomp)
      assert_equal %w(0000000000000001 0000000000000011), result
    end
  end
end
