# frozen_string_literal: true

require_relative 'helper'

class BuilderResolveTest < Twenty48Test
  def test_resolved_win_states_2x2
    builder = Twenty48::Builder.new(2, 2)
    assert_states_equal [[
      0, 0,
      0, 2
    ]], builder.resolved_win_states

    builder = Twenty48::Builder.new(2, 2, 1)
    assert_states_equal [[
      0, 0,
      0, 2
    ], [
      0, 0,
      1, 1
    ]], builder.resolved_win_states

    builder = Twenty48::Builder.new(2, 3)
    assert_states_equal [[
      0, 0,
      0, 3
    ]], builder.resolved_win_states

    builder = Twenty48::Builder.new(2, 3, 1)
    assert_states_equal [[
      0, 0,
      0, 3
    ], [
      0, 0,
      2, 2
    ]], builder.resolved_win_states

    builder = Twenty48::Builder.new(2, 3, 2)
    assert_states_equal [[
      0, 0,
      0, 3
    ], [
      0, 0,
      2, 2
    ], [ # Win with down and then right.
      0, 1,
      2, 1
    ]], builder.resolved_win_states
  end

  def test_resolved_win_states_3x3
    builder = Twenty48::Builder.new(3, 3)
    assert_states_equal [[
      0, 0, 0,
      0, 0, 0,
      0, 0, 3
    ]], builder.resolved_win_states

    builder = Twenty48::Builder.new(3, 3, 1)
    assert_states_equal [[
      0, 0, 0,
      0, 0, 0,
      0, 0, 3
    ], [
      0, 0, 0,
      0, 0, 0,
      0, 2, 2
    ]], builder.resolved_win_states

    builder = Twenty48::Builder.new(3, 3, 2)
    assert_states_equal [[
      0, 0, 0,
      0, 0, 0,
      0, 0, 3
    ], [
      0, 0, 0,
      0, 0, 0,
      0, 2, 2
    ], [
      0, 0, 0,
      0, 0, 0,
      1, 1, 2
    ]], builder.resolved_win_states

    # Cannot yet handle this case.
    assert_raises { Twenty48::Builder.new(3, 3, 3) }
  end

  def test_resolved_win_states_4x4
    builder = Twenty48::Builder.new(4, 3)
    assert_states_equal [[
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 3
    ]], builder.resolved_win_states

    builder = Twenty48::Builder.new(4, 3, 1)
    assert_states_equal [[
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 3
    ], [
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 2, 2
    ]], builder.resolved_win_states

    builder = Twenty48::Builder.new(4, 3, 2)
    assert_states_equal [[
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 3
    ], [
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 2, 2
    ], [
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 1, 1, 2
    ]], builder.resolved_win_states

    assert_raises { builder = Twenty48::Builder.new(4, 3, 3) }
  end

  def test_resolved_lose_state_2x2
    builder = Twenty48::Builder.new(2, 2)
    assert_equal Twenty48::State.new([
      0, 0,
      0, 0
    ]), builder.resolved_lose_state
  end

  def test_win_in_2x2
    builder = Twenty48::Builder.new(2, 3)

    assert builder.win_in?(Twenty48::State.new([0, 0, 0, 3]), 0)
    assert builder.win_in?(Twenty48::State.new([0, 0, 2, 2]), 1)
    refute builder.win_in?(Twenty48::State.new([0, 1, 1, 2]), 1)
    assert builder.win_in?(Twenty48::State.new([1, 0, 1, 2]), 2)
    refute builder.win_in?(Twenty48::State.new([0, 1, 1, 2]), 2)
  end

  def test_lose_in_3x3
    builder = Twenty48::Builder.new(3, 6)

    assert builder.lose_in?(Twenty48::State.new([
      1, 2, 1,
      2, 1, 2,
      1, 2, 1
    ]), 0)

    refute builder.lose_in?(Twenty48::State.new([
      0, 2, 1,
      2, 1, 2,
      1, 2, 1
    ]), 1)

    # Not sure if this is reachable, but it does serve for the test.
    assert builder.lose_in?(Twenty48::State.new([
      3, 3, 3,
      5, 1, 5,
      1, 5, 1
    ]), 1)
  end

  def test_resolve_state_array_2x2
    builder = Twenty48::Builder.new(2, 3, 1)

    # Nothing to do.
    assert_equal Twenty48::State.new([
      0, 0,
      0, 1
    ]), builder.resolve(Twenty48::State.new([
      0, 0,
      0, 1
    ]))

    # 1-to-win state.
    assert_equal Twenty48::State.new([
      0, 0,
      2, 2
    ]), builder.resolve(Twenty48::State.new([
      0, 0,
      2, 2
    ]))

    # 1-to-win state mapped to resolved 1-to-win state.
    assert_equal Twenty48::State.new([
      0, 0,
      2, 2
    ]), builder.resolve(Twenty48::State.new([
      0, 1,
      2, 2
    ]))
  end
end
