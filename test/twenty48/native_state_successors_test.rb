# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/state_successors_tests'

class NativeStateSuccessorsTest < Twenty48NativeTest
  include Twenty48

  # This is where most of the actual tests are defined; they call
  # #state_random_successors. TODO: actually true?
  include CommonStateSuccessorsTests

  def test_random_transitions_2x2
    state = make_state([0, 0, 0, 0])
    transitions = state.random_transitions
    assert_equal 2, transitions.size
    assert_close 0.9, transitions[make_state([0, 0, 0, 1])]
    assert_close 0.1, transitions[make_state([0, 0, 0, 2])]
  end

  def test_random_transitions_3x3
    state = make_state([
      0, 0, 0,
      0, 0, 0,
      0, 0, 0
    ])
    transitions = state.random_transitions
    assert_equal 6, transitions.size
    assert_close 1.0, transitions.values.inject(&:+)
    assert_close 0.4, transitions[make_state([
      0, 0, 0,
      0, 0, 0,
      0, 0, 1
    ])]
    assert_close 0.4 / 9, transitions[make_state([
      0, 0, 0,
      0, 0, 0,
      0, 0, 2
    ])]
    assert_close 0.4, transitions[make_state([
      0, 0, 0,
      0, 0, 0,
      0, 1, 0
    ])]
    assert_close 0.4 / 9, transitions[make_state([
      0, 0, 0,
      0, 0, 0,
      0, 2, 0
    ])]
    assert_close 0.1, transitions[make_state([
      0, 0, 0,
      0, 1, 0,
      0, 0, 0
    ])]
    assert_close 0.1 / 9, transitions[make_state([
      0, 0, 0,
      0, 2, 0,
      0, 0, 0
    ])]
  end
end
