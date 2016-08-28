# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../../lib/twenty_48'

class StateTest < Minitest::Test
  def test_hash
    state = Twenty48::State.new([0, 0, 0, 0])
    assert_equal "\x00\x00\x00\x00".hash, state.hash

    state = Twenty48::State.new([0, 0, 0, 1])
    assert_equal "\x00\x00\x00\x01".hash, state.hash
  end

  def test_eql?
    state0 = Twenty48::State.new([0, 0, 0, 0])
    state1 = Twenty48::State.new([0, 0, 0, 0])
    state2 = Twenty48::State.new([0, 0, 0, 1])

    assert state0.eql?(state0)
    assert state0.eql?(state1)
    refute state0.eql?(state2)
  end

  def test_pretty_print_2x2
    state = Twenty48::State.new([0, 0, 0, 0])
    assert_equal "   .    .\n   .    .", state.pretty_print

    state = Twenty48::State.new([1, 0, 0, 0])
    assert_equal "   2    .\n   .    .", state.pretty_print

    state = Twenty48::State.new([1, 2, 0, 0])
    assert_equal "   2    4\n   .    .", state.pretty_print

    state = Twenty48::State.new([1, 1, 2, 0])
    assert_equal "   2    2\n   4    .", state.pretty_print

    state = Twenty48::State.new([1, 1, 1, 2])
    assert_equal "   2    2\n   2    4", state.pretty_print
  end

  def test_inspect_2x2
    state = Twenty48::State.new([0, 0, 0, 0])
    assert_equal '[0, 0, 0, 0]', state.inspect

    state = Twenty48::State.new([1, 0, 0, 0])
    assert_equal '[1, 0, 0, 0]', state.inspect
  end

  def test_reflect_2x2
    state = Twenty48::State.new([0, 1, 2, 3])
    assert_equal [
      0, 1,
      2, 3
    ], state.to_a

    assert_instance_of Twenty48::State, state.reflect_horizontally
    assert_equal [
      0, 1,
      2, 3
    ], state.to_a # unchanged
    assert_equal [
      1, 0,
      3, 2
    ], state.reflect_horizontally.to_a

    assert_instance_of Twenty48::State, state.reflect_vertically
    assert_equal [
      0, 1,
      2, 3
    ], state.to_a # unchanged
    assert_equal [
      2, 3,
      0, 1
    ], state.reflect_vertically.to_a

    assert_instance_of Twenty48::State, state.transpose
    assert_equal [
      0, 1,
      2, 3
    ], state.to_a # unchanged
    assert_equal [
      0, 2,
      1, 3
    ], state.transpose.to_a

    assert_equal [
      3, 2,
      1, 0
    ], state.reflect_horizontally.reflect_vertically.to_a
  end

  def test_reflect_3x3
    state = Twenty48::State.new([0, 1, 2, 3, 4, 5, 6, 7, 8])
    assert_equal [
      0, 1, 2,
      3, 4, 5,
      6, 7, 8
    ], state.to_a

    assert_equal [
      2, 1, 0,
      5, 4, 3,
      8, 7, 6
    ], state.reflect_horizontally.to_a

    assert_equal [
      6, 7, 8,
      3, 4, 5,
      0, 1, 2
    ], state.reflect_vertically.to_a

    assert_equal [
      0, 3, 6,
      1, 4, 7,
      2, 5, 8
    ], state.transpose.to_a

    assert_equal [
      8, 7, 6,
      5, 4, 3,
      2, 1, 0
    ], state.reflect_horizontally.reflect_vertically.to_a
  end

  def test_random_successors_2x2
    state = Twenty48::State.new([0, 0, 0, 0])
    assert_equal [
      [1, 0, 0, 0],
      [2, 0, 0, 0],
      [0, 1, 0, 0],
      [0, 2, 0, 0],
      [0, 0, 1, 0],
      [0, 0, 2, 0],
      [0, 0, 0, 1],
      [0, 0, 0, 2]
    ].map { |state_array| Twenty48::State.new(state_array) },
      state.random_successors
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
