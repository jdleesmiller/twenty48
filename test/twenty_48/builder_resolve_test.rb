# frozen_string_literal: true

require_relative 'helper'

class BuilderResolveTest < Twenty48Test
  def test_win_in_2x2
    builder = Twenty48::Builder.new(2, 3)
    resolver = Twenty48::ExactResolver.new(builder, 2)

    assert resolver.win_in?(Twenty48::State.new([0, 0, 0, 3]), 0)
    assert resolver.win_in?(Twenty48::State.new([0, 0, 2, 2]), 1)
    refute resolver.win_in?(Twenty48::State.new([0, 1, 1, 2]), 1)
    assert resolver.win_in?(Twenty48::State.new([1, 0, 1, 2]), 2)
    refute resolver.win_in?(Twenty48::State.new([0, 1, 1, 2]), 2)
  end

  def test_moves_to_win_4x4_to_16_resolve_3
    builder = Twenty48::Builder.new(4, 4)
    resolver = Twenty48::ExactResolver.new(builder, 3)

    assert resolver.win_in?(Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 0,
      2, 0, 0, 2,
      0, 0, 0, 3
    ]), 2)

    assert resolver.win_in?(Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 1,
      2, 1, 2, 3,
      0, 2, 1, 2
    ]), 3)
  end

  def test_lose_within_2x2_to_64
    builder = Twenty48::Builder.new(2, 6)
    resolver = Twenty48::UnknownZerosResolver.new(builder, 2)

    state = Twenty48::State.new([
      2, 3,
      5, 3
    ])

    refute resolver.lose_within?(state, 1)
    assert resolver.lose_within?(state, 2)
  end

  def test_lose_within_3x3
    builder = Twenty48::Builder.new(3, 6)
    resolver = Twenty48::Resolver.new(builder, 1)

    assert resolver.lose_within?(Twenty48::State.new([
      1, 2, 1,
      2, 1, 2,
      1, 2, 1
    ]), 0)

    refute resolver.lose_within?(Twenty48::State.new([
      0, 2, 1,
      2, 1, 2,
      1, 2, 1
    ]), 1)

    # Not sure if this is reachable, but it does serve for the test.
    assert resolver.lose_within?(Twenty48::State.new([
      3, 3, 3,
      5, 1, 5,
      1, 5, 1
    ]), 1)
  end

  def test_resolve_state_array_2x2
    builder = Twenty48::Builder.new(2, 3)
    resolver = Twenty48::UnknownZerosResolver.new(builder, 1)

    # Nothing to do.
    assert_equal Twenty48::State.new([
      0, 0,
      0, 1
    ]), resolver.resolve(Twenty48::State.new([
      0, 0,
      0, 1
    ]))

    # 1-to-win state.
    assert_equal Twenty48::State.new([
      0, 0,
      2, 2
    ]), resolver.resolve(Twenty48::State.new([
      0, 0,
      2, 2
    ]))

    # 1-to-win state mapped to resolved 1-to-win state.
    assert_equal Twenty48::State.new([
      0, 0,
      2, 2
    ]), resolver.resolve(Twenty48::State.new([
      0, 1,
      2, 2
    ]))
  end
end
