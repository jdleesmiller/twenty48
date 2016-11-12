# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/state_tests'

class StateTest < Minitest::Test
  include Twenty48
  include CommonStateTests

  # For compatibility with native tests.
  def make_state(state_array)
    State.new(state_array)
  end

  def test_hash
    state = Twenty48::State.new([0, 0, 0, 0])
    assert_equal "\x00\x00\x00\x00".hash, state.hash

    state = Twenty48::State.new([0, 0, 0, 1])
    assert_equal "\x00\x00\x00\x01".hash, state.hash
  end

  def test_reflect_returns_new_state_2x2
    state = Twenty48::State.new([0, 1, 2, 3])

    # Note: The values are tested in a common/state_tests.
    assert_instance_of Twenty48::State, state.reflect_horizontally
    assert_instance_of Twenty48::State, state.reflect_vertically
    assert_instance_of Twenty48::State, state.transpose
  end

  def test_canonicalize_2x2
    state = Twenty48::State.new([0, 0, 0, 0])
    assert_equal state, state.canonicalize

    canonical_state = [0, 0,
                       0, 1]

    assert_equal canonical_state, Twenty48::State.new([
      1, 0,
      0, 0
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      0, 1,
      0, 0
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      0, 0,
      1, 0
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      0, 0,
      0, 1
    ]).canonicalize.to_a

    canonical_state = [0, 0,
                       1, 2]

    assert_equal canonical_state, Twenty48::State.new([
      1, 2,
      0, 0
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      0, 1,
      0, 2
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      0, 0,
      2, 1
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      2, 0,
      1, 0
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      1, 0,
      2, 0
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      0, 0,
      1, 2
    ]).canonicalize.to_a

    canonical_state = [0, 1,
                       2, 3]

    assert_equal canonical_state, Twenty48::State.new([
      2, 3,
      0, 1
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      0, 2,
      1, 3
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      1, 0,
      3, 2
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      3, 1,
      2, 0
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      1, 3,
      0, 2
    ]).canonicalize.to_a

    assert_equal canonical_state, Twenty48::State.new([
      0, 2,
      1, 3
    ]).canonicalize.to_a
  end
end
