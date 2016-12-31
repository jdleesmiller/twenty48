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
    return nil if value.nan?

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
end
