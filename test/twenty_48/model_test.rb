require 'minitest/autorun'

require_relative '../../lib/twenty_48'

class ModelTest < Minitest::Test
  def test_pretty_print_state_2x2
    model = Twenty48::Model.new(2, 2)
    assert_equal "   .    .\n   .    .",
      model.pretty_print_state([0, 0, 0, 0])

    assert_equal "   2    .\n   .    .",
      model.pretty_print_state([1, 0, 0, 0])

    assert_equal "   2    4\n   .    .",
      model.pretty_print_state([1, 2, 0, 0])

    assert_equal "   2    2\n   4    .",
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
  end

  def test_move_line_2
    model = Twenty48::Model.new(2, 3)

    assert_equal [0, 0], model.move_line([0, 0])
    assert_equal [1, 0], model.move_line([0, 1])
    assert_equal [2, 0], model.move_line([0, 2])

    assert_equal [1, 0], model.move_line([1, 0])
    assert_equal [2, 0], model.move_line([1, 1])
    assert_equal [1, 2], model.move_line([1, 2])

    assert_equal [2, 0], model.move_line([2, 0])
    assert_equal [2, 1], model.move_line([2, 1])
    assert_equal [3, 0], model.move_line([2, 2])
  end

  def test_move_line_3
    model = Twenty48::Model.new(3, 3)

    assert_equal [0, 0, 0], model.move_line([0, 0, 0])
    assert_equal [1, 0, 0], model.move_line([0, 0, 1])
    assert_equal [2, 0, 0], model.move_line([0, 0, 2])
    assert_equal [3, 0, 0], model.move_line([0, 0, 3])

    assert_equal [1, 0, 0], model.move_line([0, 1, 0])
    assert_equal [2, 0, 0], model.move_line([0, 1, 1])
    assert_equal [1, 2, 0], model.move_line([0, 1, 2])
    assert_equal [1, 3, 0], model.move_line([0, 1, 3])

    assert_equal [2, 0, 0], model.move_line([0, 2, 0])
    assert_equal [2, 1, 0], model.move_line([0, 2, 1])
    assert_equal [3, 0, 0], model.move_line([0, 2, 2])
    assert_equal [2, 3, 0], model.move_line([0, 2, 3])

    assert_equal [2, 0, 0], model.move_line([0, 2, 0])
    assert_equal [2, 1, 0], model.move_line([0, 2, 1])
    assert_equal [3, 0, 0], model.move_line([0, 2, 2])
    assert_equal [2, 3, 0], model.move_line([0, 2, 3])

    assert_equal [3, 0, 0], model.move_line([0, 3, 0])
    assert_equal [3, 1, 0], model.move_line([0, 3, 1])
    assert_equal [3, 2, 0], model.move_line([0, 3, 2])
    assert_equal [4, 0, 0], model.move_line([0, 3, 3])

    assert_equal [1, 0, 0], model.move_line([1, 0, 0])
    assert_equal [2, 0, 0], model.move_line([1, 0, 1])
    assert_equal [1, 2, 0], model.move_line([1, 0, 2])
    assert_equal [1, 3, 0], model.move_line([1, 0, 3])

    assert_equal [2, 0, 0], model.move_line([1, 1, 0])
    assert_equal [2, 1, 0], model.move_line([1, 1, 1])
    assert_equal [2, 2, 0], model.move_line([1, 1, 2]) # checked
    assert_equal [2, 3, 0], model.move_line([1, 1, 3])

    assert_equal [1, 2, 0], model.move_line([1, 2, 0])
    assert_equal [1, 2, 1], model.move_line([1, 2, 1])
    assert_equal [1, 3, 0], model.move_line([1, 2, 2])
    assert_equal [1, 2, 3], model.move_line([1, 2, 3])

    assert_equal [1, 3, 0], model.move_line([1, 3, 0])
    assert_equal [1, 3, 1], model.move_line([1, 3, 1])
    assert_equal [1, 3, 2], model.move_line([1, 3, 2])
    assert_equal [1, 4, 0], model.move_line([1, 3, 3])

    assert_equal [2, 0, 0], model.move_line([2, 0, 0])
    assert_equal [2, 1, 0], model.move_line([2, 0, 1])
    assert_equal [3, 0, 0], model.move_line([2, 0, 2])
    assert_equal [2, 3, 0], model.move_line([2, 0, 3])

    assert_equal [2, 1, 0], model.move_line([2, 1, 0])
    assert_equal [2, 2, 0], model.move_line([2, 1, 1]) # checked
    assert_equal [2, 1, 2], model.move_line([2, 1, 2])
    assert_equal [2, 1, 3], model.move_line([2, 1, 3])

    assert_equal [3, 0, 0], model.move_line([2, 2, 0])
    assert_equal [3, 1, 0], model.move_line([2, 2, 1])
    assert_equal [3, 2, 0], model.move_line([2, 2, 2]) # checked
    assert_equal [3, 3, 0], model.move_line([2, 2, 3]) # checked

    assert_equal [2, 3, 0], model.move_line([2, 3, 0])
    assert_equal [2, 3, 1], model.move_line([2, 3, 1])
    assert_equal [2, 3, 2], model.move_line([2, 3, 2])
    assert_equal [2, 4, 0], model.move_line([2, 3, 3])

    assert_equal [3, 0, 0], model.move_line([3, 0, 0])
    assert_equal [3, 1, 0], model.move_line([3, 0, 1])
    assert_equal [3, 2, 0], model.move_line([3, 0, 2])
    assert_equal [4, 0, 0], model.move_line([3, 0, 3])

    assert_equal [3, 1, 0], model.move_line([3, 1, 0])
    assert_equal [3, 2, 0], model.move_line([3, 1, 1])
    assert_equal [3, 1, 2], model.move_line([3, 1, 2])
    assert_equal [3, 1, 3], model.move_line([3, 1, 3])

    assert_equal [3, 2, 0], model.move_line([3, 2, 0])
    assert_equal [3, 2, 1], model.move_line([3, 2, 1])
    assert_equal [3, 3, 0], model.move_line([3, 2, 2])
    assert_equal [3, 2, 3], model.move_line([3, 2, 3])

    assert_equal [4, 0, 0], model.move_line([3, 3, 0])
    assert_equal [4, 1, 0], model.move_line([3, 3, 1])
    assert_equal [4, 2, 0], model.move_line([3, 3, 2])
    assert_equal [4, 3, 0], model.move_line([3, 3, 3])
  end

  def test_move_line_4
    model = Twenty48::Model.new(4, 4)

    assert_equal [0, 0, 0, 0], model.move_line([0, 0, 0, 0])
    assert_equal [1, 0, 0, 0], model.move_line([0, 0, 0, 1])
    assert_equal [2, 0, 0, 0], model.move_line([0, 0, 0, 2])

    assert_equal [1, 0, 0, 0], model.move_line([0, 0, 1, 0])
    assert_equal [2, 0, 0, 0], model.move_line([0, 0, 1, 1])
    assert_equal [1, 2, 0, 0], model.move_line([0, 0, 1, 2])

    assert_equal [2, 0, 0, 0], model.move_line([0, 0, 2, 0])
    assert_equal [2, 1, 0, 0], model.move_line([0, 0, 2, 1])
    assert_equal [3, 0, 0, 0], model.move_line([0, 0, 2, 2])

    assert_equal [1, 0, 0, 0], model.move_line([0, 1, 0, 0])
    assert_equal [2, 0, 0, 0], model.move_line([0, 1, 0, 1])
    assert_equal [1, 2, 0, 0], model.move_line([0, 1, 0, 2])

    assert_equal [2, 0, 0, 0], model.move_line([0, 1, 1, 0])
    assert_equal [2, 1, 0, 0], model.move_line([0, 1, 1, 1]) # checked
    assert_equal [2, 2, 0, 0], model.move_line([0, 1, 1, 2])

    assert_equal [1, 2, 0, 0], model.move_line([0, 1, 2, 0])
    assert_equal [1, 2, 1, 0], model.move_line([0, 1, 2, 1])
    assert_equal [1, 3, 0, 0], model.move_line([0, 1, 2, 2])

    assert_equal [2, 0, 0, 0], model.move_line([0, 2, 0, 0])
    assert_equal [2, 1, 0, 0], model.move_line([0, 2, 0, 1])
    assert_equal [3, 0, 0, 0], model.move_line([0, 2, 0, 2])

    assert_equal [2, 1, 0, 0], model.move_line([0, 2, 1, 0])
    assert_equal [2, 2, 0, 0], model.move_line([0, 2, 1, 1])
    assert_equal [2, 1, 2, 0], model.move_line([0, 2, 1, 2])

    assert_equal [3, 0, 0, 0], model.move_line([0, 2, 2, 0])
    assert_equal [3, 1, 0, 0], model.move_line([0, 2, 2, 1])
    assert_equal [3, 2, 0, 0], model.move_line([0, 2, 2, 2])


    assert_equal [1, 0, 0, 0], model.move_line([1, 0, 0, 0])
    assert_equal [2, 0, 0, 0], model.move_line([1, 0, 0, 1])
    assert_equal [1, 2, 0, 0], model.move_line([1, 0, 0, 2])

    assert_equal [2, 0, 0, 0], model.move_line([1, 0, 1, 0])
    assert_equal [2, 1, 0, 0], model.move_line([1, 0, 1, 1])
    assert_equal [2, 2, 0, 0], model.move_line([1, 0, 1, 2])

    assert_equal [1, 2, 0, 0], model.move_line([1, 0, 2, 0])
    assert_equal [1, 2, 1, 0], model.move_line([1, 0, 2, 1])
    assert_equal [1, 3, 0, 0], model.move_line([1, 0, 2, 2])

    assert_equal [2, 0, 0, 0], model.move_line([1, 1, 0, 0])
    assert_equal [2, 1, 0, 0], model.move_line([1, 1, 0, 1])
    assert_equal [2, 2, 0, 0], model.move_line([1, 1, 0, 2])

    assert_equal [2, 1, 0, 0], model.move_line([1, 1, 1, 0])
    assert_equal [2, 2, 0, 0], model.move_line([1, 1, 1, 1]) # checked
    assert_equal [2, 1, 2, 0], model.move_line([1, 1, 1, 2]) # checked

    assert_equal [2, 2, 0, 0], model.move_line([1, 1, 2, 0])
    assert_equal [2, 2, 1, 0], model.move_line([1, 1, 2, 1])
    assert_equal [2, 3, 0, 0], model.move_line([1, 1, 2, 2]) # checked

    assert_equal [1, 2, 0, 0], model.move_line([1, 2, 0, 0])
    assert_equal [1, 2, 1, 0], model.move_line([1, 2, 0, 1])
    assert_equal [1, 3, 0, 0], model.move_line([1, 2, 0, 2])

    assert_equal [1, 2, 1, 0], model.move_line([1, 2, 1, 0])
    assert_equal [1, 2, 2, 0], model.move_line([1, 2, 1, 1]) # checked
    assert_equal [1, 2, 1, 2], model.move_line([1, 2, 1, 2])

    assert_equal [1, 3, 0, 0], model.move_line([1, 2, 2, 0])
    assert_equal [1, 3, 1, 0], model.move_line([1, 2, 2, 1])
    assert_equal [1, 3, 2, 0], model.move_line([1, 2, 2, 2]) # checked


    assert_equal [2, 0, 0, 0], model.move_line([2, 0, 0, 0])
    assert_equal [2, 1, 0, 0], model.move_line([2, 0, 0, 1])
    assert_equal [3, 0, 0, 0], model.move_line([2, 0, 0, 2])

    assert_equal [2, 1, 0, 0], model.move_line([2, 0, 1, 0])
    assert_equal [2, 2, 0, 0], model.move_line([2, 0, 1, 1]) # checked
    assert_equal [2, 1, 2, 0], model.move_line([2, 0, 1, 2])

    assert_equal [3, 0, 0, 0], model.move_line([2, 0, 2, 0])
    assert_equal [3, 1, 0, 0], model.move_line([2, 0, 2, 1])
    assert_equal [3, 2, 0, 0], model.move_line([2, 0, 2, 2]) # checked

    assert_equal [2, 1, 0, 0], model.move_line([2, 1, 0, 0])
    assert_equal [2, 2, 0, 0], model.move_line([2, 1, 0, 1]) # checked
    assert_equal [2, 1, 2, 0], model.move_line([2, 1, 0, 2])

    assert_equal [2, 2, 0, 0], model.move_line([2, 1, 1, 0]) # checked
    assert_equal [2, 2, 1, 0], model.move_line([2, 1, 1, 1]) # checked
    assert_equal [2, 2, 2, 0], model.move_line([2, 1, 1, 2]) # checked

    assert_equal [2, 1, 2, 0], model.move_line([2, 1, 2, 0])
    assert_equal [2, 1, 2, 1], model.move_line([2, 1, 2, 1])
    assert_equal [2, 1, 3, 0], model.move_line([2, 1, 2, 2])

    assert_equal [3, 0, 0, 0], model.move_line([2, 2, 0, 0])
    assert_equal [3, 1, 0, 0], model.move_line([2, 2, 0, 1])
    assert_equal [3, 2, 0, 0], model.move_line([2, 2, 0, 2]) # checked

    assert_equal [3, 1, 0, 0], model.move_line([2, 2, 1, 0])
    assert_equal [3, 2, 0, 0], model.move_line([2, 2, 1, 1]) # checked
    assert_equal [3, 1, 2, 0], model.move_line([2, 2, 1, 2])

    assert_equal [3, 2, 0, 0], model.move_line([2, 2, 2, 0])
    assert_equal [3, 2, 1, 0], model.move_line([2, 2, 2, 1])
    assert_equal [3, 3, 0, 0], model.move_line([2, 2, 2, 2])
  end

  def test_move_2x2_up
    model = Twenty48::Model.new(2, 3)

    assert_equal [
      0, 0,
      0, 0], model.move([
      0, 0,
      0, 0], :up)

    assert_equal [
      0, 1,
      0, 0], model.move([
      0, 1,
      0, 0], :up)

    assert_equal [
      0, 1,
      0, 0], model.move([
      0, 0,
      0, 1], :up)

    assert_equal [
      1, 0,
      0, 0], model.move([
      0, 0,
      1, 0], :up)

    assert_equal [
      1, 1,
      0, 0], model.move([
      0, 0,
      1, 1], :up)

    assert_equal [
      0, 2,
      0, 0], model.move([
      0, 1,
      0, 1], :up)

    assert_equal [
      1, 2,
      0, 0], model.move([
      1, 1,
      0, 1], :up)

    assert_equal [
      2, 2,
      0, 0], model.move([
      1, 1,
      1, 1], :up)
  end

  def test_move_2x2_right
    model = Twenty48::Model.new(2, 3)

    assert_equal [
      0, 0,
      0, 0], model.move([
      0, 0,
      0, 0], :right)

    assert_equal [
      0, 1,
      0, 0], model.move([
      0, 1,
      0, 0], :right)

    assert_equal [
      0, 0,
      0, 1], model.move([
      0, 0,
      0, 1], :right)

    assert_equal [
      0, 0,
      0, 1], model.move([
      0, 0,
      1, 0], :right)

    assert_equal [
      0, 0,
      0, 2], model.move([
      0, 0,
      1, 1], :right)

    assert_equal [
      0, 1,
      0, 1], model.move([
      0, 1,
      0, 1], :right)

    assert_equal [
      0, 2,
      0, 1], model.move([
      1, 1,
      0, 1], :right)

    assert_equal [
      0, 2,
      0, 2], model.move([
      1, 1,
      1, 1], :right)
  end

  def test_move_2x2_down
    model = Twenty48::Model.new(2, 3)

    assert_equal [
      0, 0,
      0, 0], model.move([
      0, 0,
      0, 0], :down)

    assert_equal [
      0, 0,
      0, 1], model.move([
      0, 1,
      0, 0], :down)

    assert_equal [
      0, 0,
      0, 1], model.move([
      0, 0,
      0, 1], :down)

    assert_equal [
      0, 0,
      1, 0], model.move([
      0, 0,
      1, 0], :down)

    assert_equal [
      0, 0,
      1, 1], model.move([
      0, 0,
      1, 1], :down)

    assert_equal [
      0, 0,
      0, 2], model.move([
      0, 1,
      0, 1], :down)

    assert_equal [
      0, 0,
      1, 2], model.move([
      1, 1,
      0, 1], :down)

    assert_equal [
      0, 0,
      2, 2], model.move([
      1, 1,
      1, 1], :down)
  end

  def test_move_2x2_left
    model = Twenty48::Model.new(2, 3)

    assert_equal [
      0, 0,
      0, 0], model.move([
      0, 0,
      0, 0], :left)

    assert_equal [
      1, 0,
      0, 0], model.move([
      0, 1,
      0, 0], :left)

    assert_equal [
      0, 0,
      1, 0], model.move([
      0, 0,
      0, 1], :left)

    assert_equal [
      0, 0,
      1, 0], model.move([
      0, 0,
      1, 0], :left)

    assert_equal [
      0, 0,
      2, 0], model.move([
      0, 0,
      1, 1], :left)

    assert_equal [
      1, 0,
      1, 0], model.move([
      0, 1,
      0, 1], :left)

    assert_equal [
      2, 0,
      1, 0], model.move([
      1, 1,
      0, 1], :left)

    assert_equal [
      2, 0,
      2, 0], model.move([
      1, 1,
      1, 1], :left)
  end

  def assert_close x, y
    assert (x - y).abs < 1e-6, "expected #{x} ~ #{y}"
  end

  def test_random_tile_successors_hash_2x2
    model = Twenty48::Model.new(2, 3)

    hash = model.random_tile_successors_hash([
      0, 0,
      0, 1])
    assert_close hash[[
      0, 0,
      1, 1]], 0.6
    assert_close hash[[
      0, 1,
      1, 0]], 0.3
    assert_close hash[[
      0, 0,
      1, 2]], 2 * 0.1 / 3
    assert_close hash[[
      0, 1,
      2, 0]], 1 * 0.1 / 3
  end

  def test_start_states_2x2
    model = Twenty48::Model.new(2, 2)
    assert_equal [
      [0, 0,
       0, 2], # canonicalized to winning state
      [0, 0,
       1, 1],
      [0, 1,
       1, 0]], model.start_states

    model = Twenty48::Model.new(2, 3)
    assert_equal [
      [0, 0,
       1, 1],
      [0, 0,
       1, 2],
      [0, 0,
       2, 2],
      [0, 1,
       1, 0],
      [0, 1,
       2, 0],
      [0, 2,
       2, 0]], model.start_states
  end

  def test_start_states_2x2_with_pre_win
    model = Twenty48::Model.new(2, 2, true)
    assert_equal [
      [0, 0,
       0, 2], # canonicalized to winning state
      [0, 0,
       1, 1], # actually the pre-win state
      [0, 1,
       1, 0]], model.start_states

    model = Twenty48::Model.new(2, 3, true)
    assert_equal [
      [0, 0,
       1, 1],
      [0, 0,
       1, 2],
      [0, 0,
       2, 2], # actually the pre-win state
      [0, 1,
       1, 0],
      [0, 1,
       2, 0],
      [0, 2,
       2, 0]], model.start_states
  end

  def test_build_hash_model_2x2_game_of_4
    model = Twenty48::Model.new(2, 2)
    hash = model.build_hash_model

    assert_equal 4, hash.size
    win = [0, 0,
           0, 2]
    side = [0, 0,
            1, 1]
    corner = [0, 1,
              1, 1]
    diag = [0, 1,
            1, 0]

    assert hash.key?(win)
    assert_equal 4, hash[win].size
    assert_close 1, hash[win][:up][win]
    assert_close 1, hash[win][:right][win]
    assert_close 1, hash[win][:down][win]
    assert_close 1, hash[win][:left][win]

    assert hash.key?(side)
    assert_equal 4, hash[side].size
    assert_close 0.9, hash[side][:up][corner]
    assert_close 0.1, hash[side][:up][win]
    assert_close 1, hash[side][:right][win]
    assert_close 1, hash[side][:down][side]
    assert_close 1, hash[side][:left][win]

    assert hash.key?(corner)
    assert_equal 4, hash[corner].size
    assert_close 1, hash[corner][:up][win]
    assert_close 1, hash[corner][:right][win]
    assert_close 1, hash[corner][:down][win]
    assert_close 1, hash[corner][:left][win]

    assert hash.key?(diag)
    assert_equal 4, hash[diag].size
    assert_close 0.9, hash[diag][:up][corner]
    assert_close 0.1, hash[diag][:up][win]
    assert_close 0.9, hash[diag][:right][corner]
    assert_close 0.1, hash[diag][:right][win]
    assert_close 0.9, hash[diag][:down][corner]
    assert_close 0.1, hash[diag][:down][win]
    assert_close 0.9, hash[diag][:left][corner]
    assert_close 0.1, hash[diag][:left][win]
  end

  def test_build_hash_model_2x2_game_of_4_pre_win
    model = Twenty48::Model.new(2, 2, true)
    hash = model.build_hash_model

    #
    # With pre-win, we lose the 'corner' state, because it has adjacent 2's,
    # which we consider a pre-win state.
    #
    assert_equal 3, hash.size
    win = [0, 0,
           0, 2]
    side = [0, 0,
            1, 1]
    diag = [0, 1,
            1, 0]

    assert hash.key?(win)
    assert_equal 4, hash[win].size
    assert_close 1, hash[win][:up][win]
    assert_close 1, hash[win][:right][win]
    assert_close 1, hash[win][:down][win]
    assert_close 1, hash[win][:left][win]

    assert hash.key?(side)
    assert_equal 4, hash[side].size
    assert_close 0.9, hash[side][:up][side] # pre-win state
    assert_close 0.1, hash[side][:up][win]
    assert_close 1, hash[side][:right][win]
    assert_close 1, hash[side][:down][side]
    assert_close 1, hash[side][:left][win]

    assert hash.key?(diag)
    assert_equal 4, hash[diag].size
    assert_close 0.9, hash[diag][:up][side] # pre-win state
    assert_close 0.1, hash[diag][:up][win]
    assert_close 0.9, hash[diag][:right][side] # pre-win state
    assert_close 0.1, hash[diag][:right][win]
    assert_close 0.9, hash[diag][:down][side] # pre-win state
    assert_close 0.1, hash[diag][:down][win]
    assert_close 0.9, hash[diag][:left][side] # pre-win state
    assert_close 0.1, hash[diag][:left][win]
  end

  def test_build_hash_model_3x3_game_of_4
    model = Twenty48::Model.new(3, 2)
    hash = model.build_hash_model

    assert_equal 23, hash.size

    win = [0, 0, 0,
           0, 0, 0,
           0, 0, 2]
    side = [0, 0, 0,
            0, 0, 0,
            0, 1, 1]

    assert hash.key?(win)
    assert_equal 4, hash[win].size
    assert_close 1, hash[win][:up][win]
    assert_close 1, hash[win][:right][win]
    assert_close 1, hash[win][:down][win]
    assert_close 1, hash[win][:left][win]

    assert hash.key?(side)
    assert_equal 4, hash[side].size
    up = hash[side][:up]
    assert_equal 8, up.size
    assert_close 0.1, up[win]
    assert_close 0.9 / 7, up[[
      0, 0, 0,
      0, 0, 0,
      1, 1, 1]] # flipped vertically
    assert_close 0.9 / 7, up[[
      0, 0, 0,
      0, 0, 1,
      0, 1, 1]] # flipped vertically
    assert_close 0.9 / 7, up[[
      0, 0, 0,
      0, 0, 1,
      1, 0, 1]] # rotated 90
    assert_close 0.9 / 7, up[[
      0, 0, 0,
      0, 0, 1,
      1, 1, 0]] # rotated 180
    assert_close 0.9 / 7, up[[
      0, 0, 0,
      0, 1, 0,
      0, 1, 1]] # flipped vertically
    assert_close 0.9 / 7, up[[
      0, 0, 0,
      1, 0, 1,
      0, 0, 1]] # rotated 90
    assert_close 0.9 / 7, up[[
      0, 0, 1,
      0, 0, 0,
      1, 1, 0]] # rotated 180
    assert_close 1, hash[side][:right][win]
    assert_close 1, hash[side][:down][side]
    assert_close 1, hash[side][:left][win]

    puts
    puts model.pretty_print_hash_model(hash)
  end

  def test_build_hash_model_3x3_game_of_4_with_pre_win
    model = Twenty48::Model.new(3, 2, true)
    hash = model.build_hash_model

    assert_equal 6, hash.size

    win = [0, 0, 0,
           0, 0, 0,
           0, 0, 2]
    side = [0, 0, 0,
            0, 0, 0,
            0, 1, 1]
    diag_t = [0, 0, 0,
              0, 0, 1,
              0, 1, 0]
    skew = [0, 0, 0,
            0, 0, 1,
            1, 0, 0]
    diag = [0, 0, 0,
            0, 1, 0,
            0, 0, 1]
    corners = [0, 0, 1,
               0, 0, 0,
               1, 0, 0]

    assert hash.key?(win)
    assert_equal 4, hash[win].size
    assert_close 1, hash[win][:up][win]
    assert_close 1, hash[win][:right][win]
    assert_close 1, hash[win][:down][win]
    assert_close 1, hash[win][:left][win]

    assert hash.key?(side)
    assert_equal 4, hash[side].size
    assert_close 0.9, hash[side][:up][side] # pre-win state
    assert_close 0.1, hash[side][:up][win]
    assert_close 1, hash[side][:right][win]
    assert_close 1, hash[side][:down][side]
    assert_close 1, hash[side][:left][win]

    assert hash.key?(diag_t)
    assert_equal 4, hash[diag_t].size
    assert_close 0.9, hash[diag_t][:up][side] # pre-win state
    assert_close 0.1, hash[diag_t][:up][win]
    assert_close 0.9, hash[diag_t][:right][side] # pre-win state
    assert_close 0.1, hash[diag_t][:right][win]
    assert_close 0.9, hash[diag_t][:down][side] # pre-win state
    assert_close 0.1, hash[diag_t][:down][win]
    assert_close 0.9, hash[diag_t][:left][side] # pre-win state
    assert_close 0.1, hash[diag_t][:left][win]

    assert hash.key?(skew)
    assert_equal 4, hash[skew].size
    assert_close 0.9, hash[diag_t][:up][side] # pre-win state
    assert_close 0.1, hash[diag_t][:up][win]
    assert_close 0.9, hash[diag_t][:right][side] # pre-win state
    assert_close 0.1, hash[diag_t][:right][win]
    assert_close 0.9, hash[diag_t][:down][side] # pre-win state
    assert_close 0.1, hash[diag_t][:down][win]
    assert_close 0.9, hash[diag_t][:left][side] # pre-win state
    assert_close 0.1, hash[diag_t][:left][win]

    assert hash.key?(diag)
    assert_equal 4, hash[diag].size
    assert_close 0.9, hash[diag][:up][side] # pre-win state
    assert_close 0.1, hash[diag][:up][win]
    assert_close 0.9, hash[diag][:right][side] # pre-win state
    assert_close 0.1, hash[diag][:right][win]
    assert_close 0.9, hash[diag][:down][side] # pre-win state
    assert_close 0.1, hash[diag][:down][win]
    assert_close 0.9, hash[diag][:left][side] # pre-win state
    assert_close 0.1, hash[diag][:left][win]

    assert hash.key?(corners)
    assert_equal 4, hash[corners].size
    assert_close 0.9, hash[corners][:up][side] # pre-win state
    assert_close 0.1, hash[corners][:up][win]
    assert_close 0.9, hash[corners][:right][side] # pre-win state
    assert_close 0.1, hash[corners][:right][win]
    assert_close 0.9, hash[corners][:down][side] # pre-win state
    assert_close 0.1, hash[corners][:down][win]
    assert_close 0.9, hash[corners][:left][side] # pre-win state
    assert_close 0.1, hash[corners][:left][win]
  end
end
