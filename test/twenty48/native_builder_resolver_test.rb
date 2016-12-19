# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/unknown_zeros_resolver_tests'

class NativeBuilderResolverToWinTest < Twenty48NativeTest
  include Twenty48
  include CommonUnknownZerosResolverTests

  def make_resolver(board_size, max_exponent, max_win_depth)
    make_builder(board_size, max_exponent, max_win_depth: max_win_depth)
  end

  def moves_to_win(native_builder, state_array)
    result = native_builder.moves_to_win(make_state(state_array))
    return nil if result == Builder2::UNKNOWN_MOVES_TO_WIN
    result
  end

  def test_unknown_moves_to_win
    assert_equal 2**64 - 1, Builder2::UNKNOWN_MOVES_TO_WIN
  end

  def test_build_model_2x2_to_4_resolve_1
    builder = make_builder(2, 2, max_lose_depth: 1, max_win_depth: 1)
    builder.build
    states = builder.closed_states

    assert_equal 4, states.size
    assert_states_equal [[
      0, 0,
      0, 0
    ], [
      0, 0,
      0, 2
    ], [ # resolved one-to-win state; also covers 'corner' state with three ones
      0, 0,
      1, 1
    ], [
      0, 1,
      1, 0
    ]], states.sort
  end
end