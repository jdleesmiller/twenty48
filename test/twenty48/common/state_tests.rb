# frozen_string_literal: true

module Twenty48
  module CommonStateTests
    def test_inspect_2x2
      assert_equal '[0, 0, 0, 0]', make_state([0, 0, 0, 0]).inspect
      assert_equal '[0, 0, 0, 1]', make_state([0, 0, 0, 1]).inspect
      assert_equal '[1, 0, 0, 0]', make_state([1, 0, 0, 0]).inspect
    end

    def test_eql?
      state0 = make_state([0, 0, 0, 0])
      state1 = make_state([0, 0, 0, 0])
      state2 = make_state([0, 0, 0, 1])

      assert state0.eql?(state0)
      assert state0.eql?(state1)
      refute state0.eql?(state2)
    end

    def test_pretty_print_2x2
      state = make_state([0, 0, 0, 0])
      assert_equal "   .    .\n   .    .", state.pretty_print

      state = make_state([1, 0, 0, 0])
      assert_equal "   2    .\n   .    .", state.pretty_print

      state = make_state([1, 2, 0, 0])
      assert_equal "   2    4\n   .    .", state.pretty_print

      state = make_state([1, 1, 2, 0])
      assert_equal "   2    2\n   4    .", state.pretty_print

      state = make_state([1, 1, 1, 2])
      assert_equal "   2    2\n   2    4", state.pretty_print
    end

    def test_reflect_2x2
      state = make_state([0, 1, 2, 3])
      assert_equal [
        0, 1,
        2, 3
      ], state.to_a

      assert_equal [
        1, 0,
        3, 2
      ], state.reflect_horizontally.to_a
      assert_equal [ # unchanged
        0, 1,
        2, 3
      ], state.to_a

      assert_equal [
        2, 3,
        0, 1
      ], state.reflect_vertically.to_a
      assert_equal [ # unchanged
        0, 1,
        2, 3
      ], state.to_a

      assert_equal [
        0, 2,
        1, 3
      ], state.transpose.to_a
      assert_equal [ # unchanged
        0, 1,
        2, 3
      ], state.to_a

      assert_equal [
        3, 2,
        1, 0
      ], state.reflect_horizontally.reflect_vertically.to_a
    end

    def test_reflect_3x3
      state = make_state([0, 1, 2, 3, 4, 5, 6, 7, 8])
      assert_equal [
        0, 1, 2,
        3, 4, 5,
        6, 7, 8
      ], state.to_a

      assert_equal [
        2, 1, 0,
        5, 4, 3,
        8, 7, 6
      ], state.reflect_horizontally.to_a

      assert_equal [
        6, 7, 8,
        3, 4, 5,
        0, 1, 2
      ], state.reflect_vertically.to_a

      assert_equal [
        0, 3, 6,
        1, 4, 7,
        2, 5, 8
      ], state.transpose.to_a

      assert_equal [
        8, 7, 6,
        5, 4, 3,
        2, 1, 0
      ], state.reflect_horizontally.reflect_vertically.to_a
    end

    def test_reflect_4x4
      state = make_state([
        0,  1,  2,  3,
        4,  5,  6,  7,
        8,  9,  10, 11,
        12, 13, 14, 15
      ])
      assert_equal [
        0,  1,  2,  3,
        4,  5,  6,  7,
        8,  9,  10, 11,
        12, 13, 14, 15
      ], state.to_a

      assert_equal [
        3,  2,  1,  0,
        7,  6,  5,  4,
        11, 10, 9,  8,
        15, 14, 13, 12
      ], state.reflect_horizontally.to_a

      assert_equal [
        12, 13, 14, 15,
        8,  9,  10, 11,
        4,  5,  6,  7,
        0,  1,  2,  3
      ], state.reflect_vertically.to_a

      assert_equal [
        0, 4, 8,  12,
        1, 5, 9,  13,
        2, 6, 10, 14,
        3, 7, 11, 15
      ], state.transpose.to_a

      assert_equal [
        15, 14, 13, 12,
        11, 10, 9,  8,
        7,  6,  5,  4,
        3,  2,  1,  0
      ], state.reflect_horizontally.reflect_vertically.to_a
    end
  end
end
