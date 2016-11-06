# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/line_tests'

class LineTest < Twenty48Test
  include Twenty48
  include Line
  include CommonLineTests

  def test_move_line_with_unknowns_2
    assert_equal [0, 0], move([0, 0], true)
    assert_equal [0, 0], move([0, 1], true)
    assert_equal [0, 0], move([0, 2], true)

    assert_equal [1, 0], move([1, 0], true)
    assert_equal [2, 0], move([1, 1], true)
    assert_equal [1, 2], move([1, 2], true)

    assert_equal [2, 0], move([2, 0], true)
    assert_equal [2, 1], move([2, 1], true)
    assert_equal [3, 0], move([2, 2], true)
  end

  def test_move_line_with_unknowns_3
    # Leading 0: All values become uncertain.
    assert_equal [0, 0, 0], move([0, 0, 0], true)
    assert_equal [0, 0, 0], move([0, 0, 1], true)

    # Leading 1: Somewhat more interesting.
    assert_equal [1, 0, 0], move([1, 0, 0], true)
    assert_equal [1, 0, 0], move([1, 0, 1], true)

    assert_equal [2, 0, 0], move([1, 1, 0], true)
    assert_equal [2, 1, 0], move([1, 1, 1], true)
    assert_equal [2, 2, 0], move([1, 1, 2], true)
    assert_equal [2, 3, 0], move([1, 1, 3], true)

    assert_equal [1, 2, 0], move([1, 2, 0], true)
    assert_equal [1, 2, 1], move([1, 2, 1], true)
    assert_equal [1, 3, 0], move([1, 2, 2], true)
    assert_equal [1, 2, 3], move([1, 2, 3], true)

    assert_equal [1, 3, 0], move([1, 3, 0], true)
    assert_equal [1, 3, 1], move([1, 3, 1], true)
    assert_equal [1, 3, 2], move([1, 3, 2], true)
    assert_equal [1, 4, 0], move([1, 3, 3], true)
  end
end
