# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../../lib/twenty_48'

class ModelResolveTest < Minitest::Test
  def test_resolved_win_states_2x2
    model = Twenty48::Model.new(2, 2)
    assert_equal [Twenty48::State.new([
      0, 0,
      0, 2
    ])], model.resolved_win_states

    model = Twenty48::Model.new(2, 2, 1)
    assert_equal [Twenty48::State.new([
      0, 0,
      0, 2
    ]), Twenty48::State.new([
      0, 0,
      1, 1
    ])], model.resolved_win_states

    model = Twenty48::Model.new(2, 3)
    assert_equal [Twenty48::State.new([
      0, 0,
      0, 3
    ])], model.resolved_win_states

    model = Twenty48::Model.new(2, 3, 1)
    assert_equal [Twenty48::State.new([
      0, 0,
      0, 3
    ]), Twenty48::State.new([
      0, 0,
      2, 2
    ])], model.resolved_win_states

    model = Twenty48::Model.new(2, 3, 2)
    assert_equal [Twenty48::State.new([
      0, 0,
      0, 3
    ]), Twenty48::State.new([
      0, 0,
      2, 2
    ]), Twenty48::State.new([ # Win with down and then right.
      0, 1,
      2, 1
    ])], model.resolved_win_states
  end

  def test_resolved_win_states_3x3
    model = Twenty48::Model.new(3, 3)
    assert_equal [Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      0, 0, 3
    ])], model.resolved_win_states

    model = Twenty48::Model.new(3, 3, 1)
    assert_equal [Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      0, 0, 3
    ]), Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      0, 2, 2
    ])], model.resolved_win_states

    model = Twenty48::Model.new(3, 3, 2)
    assert_equal [Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      0, 0, 3
    ]), Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      0, 2, 2
    ]), Twenty48::State.new([
      0, 0, 0,
      0, 0, 0,
      1, 1, 2
    ])], model.resolved_win_states

    # Cannot yet handle this case.
    assert_raises { Twenty48::Model.new(3, 3, 3) }
  end

  def test_resolved_win_states_4x4
    model = Twenty48::Model.new(4, 3)
    assert_equal [Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 3
    ])], model.resolved_win_states

    model = Twenty48::Model.new(4, 3, 1)
    assert_equal [Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 3
    ]), Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 2, 2
    ])], model.resolved_win_states

    model = Twenty48::Model.new(4, 3, 2)
    assert_equal [Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 3
    ]), Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 2, 2
    ]), Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0,
      0, 1, 1, 2
    ])], model.resolved_win_states

    assert_raises { model = Twenty48::Model.new(4, 3, 3) }
  end

  def test_resolved_lose_state_2x2
    model = Twenty48::Model.new(2, 2)
    assert_equal Twenty48::State.new([
      0, 0,
      0, 0
    ]), model.resolved_lose_state
  end

  def test_win_in_2x2
    model = Twenty48::Model.new(2, 3)

    assert model.win_in?(Twenty48::State.new([0, 0, 0, 3]), 0)
    assert model.win_in?(Twenty48::State.new([0, 0, 2, 2]), 1)
    refute model.win_in?(Twenty48::State.new([0, 1, 1, 2]), 1)
    assert model.win_in?(Twenty48::State.new([1, 0, 1, 2]), 2)
    refute model.win_in?(Twenty48::State.new([0, 1, 1, 2]), 2)
  end

  def test_lose_in_3x3
    model = Twenty48::Model.new(3, 6)

    assert model.lose_in?(Twenty48::State.new([
      1, 2, 1,
      2, 1, 2,
      1, 2, 1
    ]), 0)

    refute model.lose_in?(Twenty48::State.new([
      0, 2, 1,
      2, 1, 2,
      1, 2, 1
    ]), 1)

    # Not sure if this is reachable, but it does serve for the test.
    assert model.lose_in?(Twenty48::State.new([
      3, 3, 3,
      5, 1, 5,
      1, 5, 1
    ]), 1)
  end

  def test_resolve_state_array_2x2
    model = Twenty48::Model.new(2, 3, 1)

    # Nothing to do.
    assert_equal Twenty48::State.new([
      0, 0,
      0, 1
    ]), model.resolve_state_array([
      0, 0,
      0, 1
    ])

    # Canonicalize.
    assert_equal Twenty48::State.new([
      0, 0,
      0, 1
    ]), model.resolve_state_array([
      0, 0,
      1, 0
    ])

    # 1-to-win state.
    assert_equal Twenty48::State.new([
      0, 0,
      2, 2
    ]), model.resolve_state_array([
      0, 0,
      2, 2
    ])

    # 1-to-win state mapped to resolved 1-to-win state.
    assert_equal Twenty48::State.new([
      0, 0,
      2, 2
    ]), model.resolve_state_array([
      0, 1,
      2, 2
    ])
  end
end
