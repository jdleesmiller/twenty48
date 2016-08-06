require 'minitest/autorun'

require_relative '../../lib/twenty_48'

class ModelTest < Minitest::Test
  def test_pretty_print_state_2x2
    model = Twenty48::Model.new(2, 2)
    assert_equal "         \n         ",
      model.pretty_print_state([0, 0, 0, 0])

    assert_equal "   2     \n         ",
      model.pretty_print_state([1, 0, 0, 0])

    assert_equal "   2    4\n         ",
      model.pretty_print_state([1, 2, 0, 0])

    assert_equal "   2    2\n   4     ",
      model.pretty_print_state([1, 1, 2, 0])

    assert_equal "   2    2\n   2    4",
      model.pretty_print_state([1, 1, 1, 2])
  end

  def test_reflect_2x2
    model = Twenty48::Model.new(2, 3)
    state = [0, 1, 2, 3]
    assert_equal [
      [0, 1],
      [2, 3]],
      model.unflatten_state(state)

    assert_equal [
      [1, 0],
      [3, 2]],
      model.unflatten_state(model.reflect_state_horizontally(state))

    assert_equal [
      [2, 3],
      [0, 1]],
      model.unflatten_state(model.reflect_state_vertically(state))

    assert_equal [
      [0, 2],
      [1, 3]],
      model.unflatten_state(model.reflect_state_diagonally(state))

    assert_equal [
      [3, 2],
      [1, 0]],
      model.unflatten_state(
        model.reflect_state_horizontally(
          model.reflect_state_vertically(state)))
  end

  def test_reflect_3x3
    model = Twenty48::Model.new(3, 8)
    state = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    assert_equal [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8]],
      model.unflatten_state(state)

    assert_equal [
      [2, 1, 0],
      [5, 4, 3],
      [8, 7, 6]],
      model.unflatten_state(model.reflect_state_horizontally(state))

    assert_equal [
      [6, 7, 8],
      [3, 4, 5],
      [0, 1, 2]],
      model.unflatten_state(model.reflect_state_vertically(state))

    assert_equal [
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8]],
      model.unflatten_state(model.reflect_state_diagonally(state))

    assert_equal [
      [8, 7, 6],
      [5, 4, 3],
      [2, 1, 0]],
      model.unflatten_state(
        model.reflect_state_horizontally(
          model.reflect_state_vertically(state)))
  end

  def test_canonicalize_2x2
    model = Twenty48::Model.new(2, 4)
    state = [0, 0, 0, 0]
    assert_equal state, model.canonicalize_state(state)

    canonical_state = [0, 0,
                       0, 1]

    assert_equal canonical_state, model.canonicalize_state(
      [1, 0,
       0, 0])

    assert_equal canonical_state, model.canonicalize_state(
      [0, 1,
       0, 0])

    assert_equal canonical_state, model.canonicalize_state(
      [0, 0,
       1, 0])

    assert_equal canonical_state, model.canonicalize_state(
      [0, 0,
       0, 1])

    canonical_state = [0, 0,
                       1, 2]

    assert_equal canonical_state, model.canonicalize_state(
      [1, 2,
       0, 0])

    assert_equal canonical_state, model.canonicalize_state(
      [0, 1,
       0, 2])

    assert_equal canonical_state, model.canonicalize_state(
      [0, 0,
       2, 1])

    assert_equal canonical_state, model.canonicalize_state(
      [2, 0,
       1, 0])

    assert_equal canonical_state, model.canonicalize_state(
      [1, 0,
       2, 0])

    assert_equal canonical_state, model.canonicalize_state(
      [0, 0,
       1, 2])

    canonical_state = [0, 1,
                       2, 3]

    assert_equal canonical_state, model.canonicalize_state(
      [2, 3,
       0, 1])

    assert_equal canonical_state, model.canonicalize_state(
      [0, 2,
       1, 3])

    assert_equal canonical_state, model.canonicalize_state(
      [1, 0,
       3, 2])

    assert_equal canonical_state, model.canonicalize_state(
      [3, 1,
       2, 0])

    assert_equal canonical_state, model.canonicalize_state(
      [1, 3,
       0, 2])

    assert_equal canonical_state, model.canonicalize_state(
      [0, 2,
       1, 3])

    # canonical_state = [
    #   0, 2,
    #   3, 1]

    # assert_equal canonical_state, model.canonicalize_state(
    #   [3, 0,
    #    1, 2])

    # assert_equal canonical_state, model.canonicalize_state(
    #   [1, 3,
    #    2, 0])

    # assert_equal canonical_state, model.canonicalize_state(
    #   [2, 0,
    #    1, 3])

    # 0 1
    # 2 3

    # rotate 90
    # 2 0
    # 3 1
    # 0 -> 1 +1  +1 mod 4
    # 1 -> 3 +2  +2 mod 4
    # 2 -> 0 -2  +3 mod
    # 3 -> 2 -1  +5 mod

    # 0 1 2
    # 3 4 5
    # 6 7 8

    # # rotate 90
    # 6 3 0
    # 7 4 1
    # 8 5 2

    # 0 -> 2 +2
    # 1 -> 5 +4
    # 2 -> 8 +6
    # 3 -> 1 -2
    # 4 -> 4 0
    # 5 -> 7 +2
    # 6 -> 0 -6
    # 7 -> 3 -4
    # 8 -> 6 -2

    # # reflect through "/" diagonal (equiv to rotate and flip VT)
    # 8 5 2
    # 7 4 1
    # 6 3 0

    # # rotate -90 (can obtain from rotate 90 by flipping HZ and VT
    # 2 5 8
    # 1 4 7
    # 0 3 6

    # # rotate 180 (equiv to flipping HZ and VT)
    # 8 7 6
    # 5 4 3
    # 2 1 0



  end
end
