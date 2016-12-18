# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/unknown_zeros_resolver_tests'

class UnknownZerosResolverTest < Twenty48Test
  include Twenty48
  include CommonUnknownZerosResolverTests

  def make_resolver(board_size, max_exponent, depth)
    builder = Builder.new(board_size, max_exponent)
    UnknownZerosResolver.new(builder, depth)
  end

  def moves_to_win(resolver, state_array)
    resolver.moves_to_definite_win(make_state(state_array))
  end

  def test_resolve_state_array_2x2
    builder = Builder.new(2, 3)
    resolver = UnknownZerosResolver.new(builder, 1)

    # Nothing to do.
    assert_equal State.new([
      0, 0,
      0, 1
    ]), resolver.resolve(State.new([
      0, 0,
      0, 1
    ]))

    # 1-to-win state.
    assert_equal State.new([
      0, 0,
      2, 2
    ]), resolver.resolve(State.new([
      0, 0,
      2, 2
    ]))

    # 1-to-win state mapped to resolved 1-to-win state.
    assert_equal State.new([
      0, 0,
      2, 2
    ]), resolver.resolve(State.new([
      0, 1,
      2, 2
    ]))
  end
end
