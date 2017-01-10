# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/state_tests'
require_relative 'common/state_adjacent_pair_with_known_tests'
require_relative 'common/state_adjacent_pair_with_unknown_tests'

class StateTest < Minitest::Test
  include Twenty48
  include CommonStateTests
  include CommonStateAdjacentPairWithKnownTests
  include CommonStateAdjacentPairWithUnknownTests

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
end
