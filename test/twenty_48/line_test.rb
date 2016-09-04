# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../../lib/twenty_48'

class LineTest < Minitest::Test
  include Twenty48::Line

  def test_move_line_2
    assert_equal [0, 0], move([0, 0])
    assert_equal [1, 0], move([0, 1])
    assert_equal [2, 0], move([0, 2])

    assert_equal [1, 0], move([1, 0])
    assert_equal [2, 0], move([1, 1])
    assert_equal [1, 2], move([1, 2])

    assert_equal [2, 0], move([2, 0])
    assert_equal [2, 1], move([2, 1])
    assert_equal [3, 0], move([2, 2])
  end

  def test_move_line_3
    assert_equal [0, 0, 0], move([0, 0, 0])
    assert_equal [1, 0, 0], move([0, 0, 1])
    assert_equal [2, 0, 0], move([0, 0, 2])
    assert_equal [3, 0, 0], move([0, 0, 3])

    assert_equal [1, 0, 0], move([0, 1, 0])
    assert_equal [2, 0, 0], move([0, 1, 1])
    assert_equal [1, 2, 0], move([0, 1, 2])
    assert_equal [1, 3, 0], move([0, 1, 3])

    assert_equal [2, 0, 0], move([0, 2, 0])
    assert_equal [2, 1, 0], move([0, 2, 1])
    assert_equal [3, 0, 0], move([0, 2, 2])
    assert_equal [2, 3, 0], move([0, 2, 3])

    assert_equal [2, 0, 0], move([0, 2, 0])
    assert_equal [2, 1, 0], move([0, 2, 1])
    assert_equal [3, 0, 0], move([0, 2, 2])
    assert_equal [2, 3, 0], move([0, 2, 3])

    assert_equal [3, 0, 0], move([0, 3, 0])
    assert_equal [3, 1, 0], move([0, 3, 1])
    assert_equal [3, 2, 0], move([0, 3, 2])
    assert_equal [4, 0, 0], move([0, 3, 3])

    assert_equal [1, 0, 0], move([1, 0, 0])
    assert_equal [2, 0, 0], move([1, 0, 1])
    assert_equal [1, 2, 0], move([1, 0, 2])
    assert_equal [1, 3, 0], move([1, 0, 3])

    assert_equal [2, 0, 0], move([1, 1, 0])
    assert_equal [2, 1, 0], move([1, 1, 1])
    assert_equal [2, 2, 0], move([1, 1, 2]) # checked
    assert_equal [2, 3, 0], move([1, 1, 3])

    assert_equal [1, 2, 0], move([1, 2, 0])
    assert_equal [1, 2, 1], move([1, 2, 1])
    assert_equal [1, 3, 0], move([1, 2, 2])
    assert_equal [1, 2, 3], move([1, 2, 3])

    assert_equal [1, 3, 0], move([1, 3, 0])
    assert_equal [1, 3, 1], move([1, 3, 1])
    assert_equal [1, 3, 2], move([1, 3, 2])
    assert_equal [1, 4, 0], move([1, 3, 3])

    assert_equal [2, 0, 0], move([2, 0, 0])
    assert_equal [2, 1, 0], move([2, 0, 1])
    assert_equal [3, 0, 0], move([2, 0, 2])
    assert_equal [2, 3, 0], move([2, 0, 3])

    assert_equal [2, 1, 0], move([2, 1, 0])
    assert_equal [2, 2, 0], move([2, 1, 1]) # checked
    assert_equal [2, 1, 2], move([2, 1, 2])
    assert_equal [2, 1, 3], move([2, 1, 3])

    assert_equal [3, 0, 0], move([2, 2, 0])
    assert_equal [3, 1, 0], move([2, 2, 1])
    assert_equal [3, 2, 0], move([2, 2, 2]) # checked
    assert_equal [3, 3, 0], move([2, 2, 3]) # checked

    assert_equal [2, 3, 0], move([2, 3, 0])
    assert_equal [2, 3, 1], move([2, 3, 1])
    assert_equal [2, 3, 2], move([2, 3, 2])
    assert_equal [2, 4, 0], move([2, 3, 3])

    assert_equal [3, 0, 0], move([3, 0, 0])
    assert_equal [3, 1, 0], move([3, 0, 1])
    assert_equal [3, 2, 0], move([3, 0, 2])
    assert_equal [4, 0, 0], move([3, 0, 3])

    assert_equal [3, 1, 0], move([3, 1, 0])
    assert_equal [3, 2, 0], move([3, 1, 1])
    assert_equal [3, 1, 2], move([3, 1, 2])
    assert_equal [3, 1, 3], move([3, 1, 3])

    assert_equal [3, 2, 0], move([3, 2, 0])
    assert_equal [3, 2, 1], move([3, 2, 1])
    assert_equal [3, 3, 0], move([3, 2, 2])
    assert_equal [3, 2, 3], move([3, 2, 3])

    assert_equal [4, 0, 0], move([3, 3, 0])
    assert_equal [4, 1, 0], move([3, 3, 1])
    assert_equal [4, 2, 0], move([3, 3, 2])
    assert_equal [4, 3, 0], move([3, 3, 3])
  end

  def test_move_line_4
    # Leading 0
    assert_equal [0, 0, 0, 0], move([0, 0, 0, 0])
    assert_equal [1, 0, 0, 0], move([0, 0, 0, 1])
    assert_equal [2, 0, 0, 0], move([0, 0, 0, 2])

    assert_equal [1, 0, 0, 0], move([0, 0, 1, 0])
    assert_equal [2, 0, 0, 0], move([0, 0, 1, 1])
    assert_equal [1, 2, 0, 0], move([0, 0, 1, 2])

    assert_equal [2, 0, 0, 0], move([0, 0, 2, 0])
    assert_equal [2, 1, 0, 0], move([0, 0, 2, 1])
    assert_equal [3, 0, 0, 0], move([0, 0, 2, 2])

    assert_equal [1, 0, 0, 0], move([0, 1, 0, 0])
    assert_equal [2, 0, 0, 0], move([0, 1, 0, 1])
    assert_equal [1, 2, 0, 0], move([0, 1, 0, 2])

    assert_equal [2, 0, 0, 0], move([0, 1, 1, 0])
    assert_equal [2, 1, 0, 0], move([0, 1, 1, 1]) # checked
    assert_equal [2, 2, 0, 0], move([0, 1, 1, 2])

    assert_equal [1, 2, 0, 0], move([0, 1, 2, 0])
    assert_equal [1, 2, 1, 0], move([0, 1, 2, 1])
    assert_equal [1, 3, 0, 0], move([0, 1, 2, 2])

    assert_equal [2, 0, 0, 0], move([0, 2, 0, 0])
    assert_equal [2, 1, 0, 0], move([0, 2, 0, 1])
    assert_equal [3, 0, 0, 0], move([0, 2, 0, 2])

    assert_equal [2, 1, 0, 0], move([0, 2, 1, 0])
    assert_equal [2, 2, 0, 0], move([0, 2, 1, 1])
    assert_equal [2, 1, 2, 0], move([0, 2, 1, 2])

    assert_equal [3, 0, 0, 0], move([0, 2, 2, 0])
    assert_equal [3, 1, 0, 0], move([0, 2, 2, 1])
    assert_equal [3, 2, 0, 0], move([0, 2, 2, 2])

    # Leading 1
    assert_equal [1, 0, 0, 0], move([1, 0, 0, 0])
    assert_equal [2, 0, 0, 0], move([1, 0, 0, 1])
    assert_equal [1, 2, 0, 0], move([1, 0, 0, 2])

    assert_equal [2, 0, 0, 0], move([1, 0, 1, 0])
    assert_equal [2, 1, 0, 0], move([1, 0, 1, 1])
    assert_equal [2, 2, 0, 0], move([1, 0, 1, 2])

    assert_equal [1, 2, 0, 0], move([1, 0, 2, 0])
    assert_equal [1, 2, 1, 0], move([1, 0, 2, 1])
    assert_equal [1, 3, 0, 0], move([1, 0, 2, 2])

    assert_equal [2, 0, 0, 0], move([1, 1, 0, 0])
    assert_equal [2, 1, 0, 0], move([1, 1, 0, 1])
    assert_equal [2, 2, 0, 0], move([1, 1, 0, 2])

    assert_equal [2, 1, 0, 0], move([1, 1, 1, 0])
    assert_equal [2, 2, 0, 0], move([1, 1, 1, 1]) # checked
    assert_equal [2, 1, 2, 0], move([1, 1, 1, 2]) # checked

    assert_equal [2, 2, 0, 0], move([1, 1, 2, 0])
    assert_equal [2, 2, 1, 0], move([1, 1, 2, 1])
    assert_equal [2, 3, 0, 0], move([1, 1, 2, 2]) # checked

    assert_equal [1, 2, 0, 0], move([1, 2, 0, 0])
    assert_equal [1, 2, 1, 0], move([1, 2, 0, 1])
    assert_equal [1, 3, 0, 0], move([1, 2, 0, 2])

    assert_equal [1, 2, 1, 0], move([1, 2, 1, 0])
    assert_equal [1, 2, 2, 0], move([1, 2, 1, 1]) # checked
    assert_equal [1, 2, 1, 2], move([1, 2, 1, 2])

    assert_equal [1, 3, 0, 0], move([1, 2, 2, 0])
    assert_equal [1, 3, 1, 0], move([1, 2, 2, 1])
    assert_equal [1, 3, 2, 0], move([1, 2, 2, 2]) # checked

    # Leading 2
    assert_equal [2, 0, 0, 0], move([2, 0, 0, 0])
    assert_equal [2, 1, 0, 0], move([2, 0, 0, 1])
    assert_equal [3, 0, 0, 0], move([2, 0, 0, 2])

    assert_equal [2, 1, 0, 0], move([2, 0, 1, 0])
    assert_equal [2, 2, 0, 0], move([2, 0, 1, 1]) # checked
    assert_equal [2, 1, 2, 0], move([2, 0, 1, 2])

    assert_equal [3, 0, 0, 0], move([2, 0, 2, 0])
    assert_equal [3, 1, 0, 0], move([2, 0, 2, 1])
    assert_equal [3, 2, 0, 0], move([2, 0, 2, 2]) # checked

    assert_equal [2, 1, 0, 0], move([2, 1, 0, 0])
    assert_equal [2, 2, 0, 0], move([2, 1, 0, 1]) # checked
    assert_equal [2, 1, 2, 0], move([2, 1, 0, 2])

    assert_equal [2, 2, 0, 0], move([2, 1, 1, 0]) # checked
    assert_equal [2, 2, 1, 0], move([2, 1, 1, 1]) # checked
    assert_equal [2, 2, 2, 0], move([2, 1, 1, 2]) # checked

    assert_equal [2, 1, 2, 0], move([2, 1, 2, 0])
    assert_equal [2, 1, 2, 1], move([2, 1, 2, 1])
    assert_equal [2, 1, 3, 0], move([2, 1, 2, 2])

    assert_equal [3, 0, 0, 0], move([2, 2, 0, 0])
    assert_equal [3, 1, 0, 0], move([2, 2, 0, 1])
    assert_equal [3, 2, 0, 0], move([2, 2, 0, 2]) # checked

    assert_equal [3, 1, 0, 0], move([2, 2, 1, 0])
    assert_equal [3, 2, 0, 0], move([2, 2, 1, 1]) # checked
    assert_equal [3, 1, 2, 0], move([2, 2, 1, 2])

    assert_equal [3, 2, 0, 0], move([2, 2, 2, 0])
    assert_equal [3, 2, 1, 0], move([2, 2, 2, 1])
    assert_equal [3, 3, 0, 0], move([2, 2, 2, 2])
  end

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
