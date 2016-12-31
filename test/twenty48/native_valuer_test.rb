# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/generic_resolver_tests'
require_relative 'common/resolver_lose_tests'

class NativeResolverValueTest < Twenty48NativeTest
  include Twenty48
  include CommonGenericResolverTests
  include CommonResolverLoseTests

  DISCOUNT = 0.95

  def make_resolver(board_size, max_exponent, max_depth)
    Twenty48::NativeValuer.create(
      board_size: board_size,
      max_exponent: max_exponent,
      max_depth: max_depth,
      discount: DISCOUNT
    )
  end

  def moves_to_win(valuer, state_array)
    # The generic tests are all in terms of number of moves to win, so we have
    # to reverse engineer the value to find that.
    value = valuer.value(make_state(state_array))
    return nil if value.nan? || value.abs < 1e-12

    moves = 0
    while (value - 1).abs > 1e-9
      value /= DISCOUNT
      moves += 1
    end
    moves
  end

  def resolve_lose?(valuer, state_array)
    valuer.value(make_state(state_array)) == 0
  end

  def test_value_2x2_to_16_resolve_4
    valuer = make_resolver(2, 4, 4)

    # See notes in test_moves_to_definite_win_2x2_to_16_resolve_3 about why
    # this state is an interesting one. The optimal action is to go left, which
    # results in a win in 4 moves with probability 0.9.
    assert_close 0.9 * DISCOUNT**4, valuer.value(make_state([
      0, 1,
      2, 3
    ]))
  end
end
