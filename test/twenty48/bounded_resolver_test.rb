# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/generic_resolver_tests'

class BoundedResolveTest < Twenty48Test
  include Twenty48
  include CommonGenericResolverTests

  def make_resolver(board_size, max_exponent, depth)
    builder = Builder.new(board_size, max_exponent)
    BoundedResolver.new(builder, depth)
  end

  def moves_to_win(resolver, state_array)
    resolver.moves_to_definite_win(make_state(state_array))
  end

  def assert_bounded_state_equals(array, state)
    (0...array.size).each do |i|
      assert_equal array[i][0], state.lower[i]
      assert_equal array[i][1], state.upper[i]
    end
  end

  def test_3x3_bounds
    state = BoundedResolver::BoundedState.from_state([
      0, 0, 0,
      0, 0, 1,
      1, 0, 2
    ])

    assert_bounded_state_equals [
      [0, 0], [0, 0], [0, 0],
      [0, 0], [0, 0], [1, 1],
      [1, 1], [0, 0], [2, 2]
    ], state

    assert_bounded_state_equals [
      [0, 2], [0, 2], [0, 2],
      [1, 1], [0, 2], [0, 2],
      [1, 1], [2, 2], [0, 2]
    ], state.move(:left)

    # In the first row, it's not actually possible to have 2^3s at this point,
    # because only one of the cells can get a 2^2 after the first move. That's
    # one thing we lose with this heuristic.
    #
    # In the last row, the middle cell could be a 2^3 now, if we got a 2^2 in
    # the bottom right after the first left move.
    assert_bounded_state_equals [
      [0, 3], [0, 3], [0, 2],
      [1, 2], [0, 3], [0, 2],
      [1, 1], [2, 3], [0, 2]
    ], state.move(:left).move(:left)
  end

  def test_correct_resolve_depth_3x3_to_8
    # See `test_incorrect_resolve_depth_3x3_to_8` for the UnknownZerosResolver.
    state = [
      0, 0, 0,
      0, 0, 1,
      1, 0, 2
    ]

    resolver_0 = make_resolver(3, 3, 0)
    assert_nil moves_to_win(resolver_0, state)

    resolver_1 = make_resolver(3, 3, 1)
    assert_nil moves_to_win(resolver_1, state)

    resolver_2 = make_resolver(3, 3, 2)
    assert_nil moves_to_win(resolver_2, state)

    resolver_3 = make_resolver(3, 3, 3)
    assert_nil moves_to_win(resolver_3, state)
  end
end
