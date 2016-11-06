# frozen_string_literal: true

require_relative 'helper'

class ResolverLoseTest < Twenty48Test
  include Twenty48

  def test_lose_within_2x2_to_64
    builder = Builder.new(2, 6)
    resolver = Resolver.new(builder, 2)

    state = State.new([
      2, 3,
      5, 3
    ])

    refute resolver.lose_within?(state, 1)
    assert resolver.lose_within?(state, 2)
  end

  def test_lose_within_3x3
    builder = Builder.new(3, 6)
    resolver = Resolver.new(builder, 1)

    assert resolver.lose_within?(State.new([
      1, 2, 1,
      2, 1, 2,
      1, 2, 1
    ]), 0)

    refute resolver.lose_within?(State.new([
      0, 2, 1,
      2, 1, 2,
      1, 2, 1
    ]), 1)

    # Not sure if this is reachable, but it does serve for the test.
    assert resolver.lose_within?(State.new([
      3, 3, 3,
      5, 1, 5,
      1, 5, 1
    ]), 1)
  end
end
