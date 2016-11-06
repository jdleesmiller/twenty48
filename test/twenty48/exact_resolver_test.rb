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
end
