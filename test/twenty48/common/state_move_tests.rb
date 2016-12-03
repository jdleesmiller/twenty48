# frozen_string_literal: true

module Twenty48
  module CommonStateMoveTests
    def test_move_2x2_left
      assert_equal [
        0, 0,
        0, 0
      ], move_state([
        0, 0,
        0, 0
      ], :left)

      assert_equal [
        1, 0,
        0, 0
      ], move_state([
        0, 1,
        0, 0
      ], :left)

      assert_equal [
        0, 0,
        1, 0
      ], move_state([
        0, 0,
        0, 1
      ], :left)

      assert_equal [
        0, 0,
        1, 0
      ], move_state([
        0, 0,
        1, 0
      ], :left)

      assert_equal [
        0, 0,
        2, 0
      ], move_state([
        0, 0,
        1, 1
      ], :left)

      assert_equal [
        1, 0,
        1, 0
      ], move_state([
        0, 1,
        0, 1
      ], :left)

      assert_equal [
        2, 0,
        1, 0
      ], move_state([
        1, 1,
        0, 1
      ], :left)

      assert_equal [
        2, 0,
        2, 0
      ], move_state([
        1, 1,
        1, 1
      ], :left)
    end

    def test_move_2x2_right
      assert_equal [
        0, 0,
        0, 0
      ], move_state([
        0, 0,
        0, 0
      ], :right)

      assert_equal [
        0, 1,
        0, 0
      ], move_state([
        0, 1,
        0, 0
      ], :right)

      assert_equal [
        0, 0,
        0, 1
      ], move_state([
        0, 0,
        0, 1
      ], :right)

      assert_equal [
        0, 0,
        0, 1
      ], move_state([
        0, 0,
        1, 0
      ], :right)

      assert_equal [
        0, 0,
        0, 2
      ], move_state([
        0, 0,
        1, 1
      ], :right)

      assert_equal [
        0, 1,
        0, 1
      ], move_state([
        0, 1,
        0, 1
      ], :right)

      assert_equal [
        0, 2,
        0, 1
      ], move_state([
        1, 1,
        0, 1
      ], :right)

      assert_equal [
        0, 2,
        0, 2
      ], move_state([
        1, 1,
        1, 1
      ], :right)
    end

    def test_move_2x2_up
      assert_equal [
        0, 0,
        0, 0
      ], move_state([
        0, 0,
        0, 0
      ], :up)

      assert_equal [
        0, 1,
        0, 0
      ], move_state([
        0, 1,
        0, 0
      ], :up)

      assert_equal [
        0, 1,
        0, 0
      ], move_state([
        0, 0,
        0, 1
      ], :up)

      assert_equal [
        1, 0,
        0, 0
      ], move_state([
        0, 0,
        1, 0
      ], :up)

      assert_equal [
        1, 1,
        0, 0
      ], move_state([
        0, 0,
        1, 1
      ], :up)

      assert_equal [
        0, 2,
        0, 0
      ], move_state([
        0, 1,
        0, 1
      ], :up)

      assert_equal [
        1, 2,
        0, 0
      ], move_state([
        1, 1,
        0, 1
      ], :up)

      assert_equal [
        2, 2,
        0, 0
      ], move_state([
        1, 1,
        1, 1
      ], :up)
    end

    def test_move_2x2_down
      assert_equal [
        0, 0,
        0, 0
      ], move_state([
        0, 0,
        0, 0
      ], :down)

      assert_equal [
        0, 0,
        0, 1
      ], move_state([
        0, 1,
        0, 0
      ], :down)

      assert_equal [
        0, 0,
        0, 1
      ], move_state([
        0, 0,
        0, 1
      ], :down)

      assert_equal [
        0, 0,
        1, 0
      ], move_state([
        0, 0,
        1, 0
      ], :down)

      assert_equal [
        0, 0,
        1, 1
      ], move_state([
        0, 0,
        1, 1
      ], :down)

      assert_equal [
        0, 0,
        0, 2
      ], move_state([
        0, 1,
        0, 1
      ], :down)

      assert_equal [
        0, 0,
        1, 2
      ], move_state([
        1, 1,
        0, 1
      ], :down)

      assert_equal [
        0, 0,
        2, 2
      ], move_state([
        1, 1,
        1, 1
      ], :down)
    end
  end
end
