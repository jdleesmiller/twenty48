# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../../lib/twenty_48'

class StateMoveTest < Minitest::Test
  def test_move_2x2_up
    assert_equal [
      0, 0,
      0, 0
    ], Twenty48::State.new([
      0, 0,
      0, 0
    ]).move(:up).to_a

    assert_equal [
      0, 1,
      0, 0
    ], Twenty48::State.new([
      0, 1,
      0, 0
    ]).move(:up).to_a

    assert_equal [
      0, 1,
      0, 0
    ], Twenty48::State.new([
      0, 0,
      0, 1
    ]).move(:up).to_a

    assert_equal [
      1, 0,
      0, 0
    ], Twenty48::State.new([
      0, 0,
      1, 0
    ]).move(:up).to_a

    assert_equal [
      1, 1,
      0, 0
    ], Twenty48::State.new([
      0, 0,
      1, 1
    ]).move(:up).to_a

    assert_equal [
      0, 2,
      0, 0
    ], Twenty48::State.new([
      0, 1,
      0, 1
    ]).move(:up).to_a

    assert_equal [
      1, 2,
      0, 0
    ], Twenty48::State.new([
      1, 1,
      0, 1
    ]).move(:up).to_a

    assert_equal [
      2, 2,
      0, 0
    ], Twenty48::State.new([
      1, 1,
      1, 1
    ]).move(:up).to_a
  end

  def test_move_2x2_right
    assert_equal [
      0, 0,
      0, 0
    ], Twenty48::State.new([
      0, 0,
      0, 0
    ]).move(:right).to_a

    assert_equal [
      0, 1,
      0, 0
    ], Twenty48::State.new([
      0, 1,
      0, 0
    ]).move(:right).to_a

    assert_equal [
      0, 0,
      0, 1
    ], Twenty48::State.new([
      0, 0,
      0, 1
    ]).move(:right).to_a

    assert_equal [
      0, 0,
      0, 1
    ], Twenty48::State.new([
      0, 0,
      1, 0
    ]).move(:right).to_a

    assert_equal [
      0, 0,
      0, 2
    ], Twenty48::State.new([
      0, 0,
      1, 1
    ]).move(:right).to_a

    assert_equal [
      0, 1,
      0, 1
    ], Twenty48::State.new([
      0, 1,
      0, 1
    ]).move(:right).to_a

    assert_equal [
      0, 2,
      0, 1
    ], Twenty48::State.new([
      1, 1,
      0, 1
    ]).move(:right).to_a

    assert_equal [
      0, 2,
      0, 2
    ], Twenty48::State.new([
      1, 1,
      1, 1
    ]).move(:right).to_a
  end

  def test_move_2x2_down
    assert_equal [
      0, 0,
      0, 0
    ], Twenty48::State.new([
      0, 0,
      0, 0
    ]).move(:down).to_a

    assert_equal [
      0, 0,
      0, 1
    ], Twenty48::State.new([
      0, 1,
      0, 0
    ]).move(:down).to_a

    assert_equal [
      0, 0,
      0, 1
    ], Twenty48::State.new([
      0, 0,
      0, 1
    ]).move(:down).to_a

    assert_equal [
      0, 0,
      1, 0
    ], Twenty48::State.new([
      0, 0,
      1, 0
    ]).move(:down).to_a

    assert_equal [
      0, 0,
      1, 1
    ], Twenty48::State.new([
      0, 0,
      1, 1
    ]).move(:down).to_a

    assert_equal [
      0, 0,
      0, 2
    ], Twenty48::State.new([
      0, 1,
      0, 1
    ]).move(:down).to_a

    assert_equal [
      0, 0,
      1, 2
    ], Twenty48::State.new([
      1, 1,
      0, 1
    ]).move(:down).to_a

    assert_equal [
      0, 0,
      2, 2
    ], Twenty48::State.new([
      1, 1,
      1, 1
    ]).move(:down).to_a
  end

  def test_move_2x2_left
    assert_equal [
      0, 0,
      0, 0
    ], Twenty48::State.new([
      0, 0,
      0, 0
    ]).move(:left).to_a

    assert_equal [
      1, 0,
      0, 0
    ], Twenty48::State.new([
      0, 1,
      0, 0
    ]).move(:left).to_a

    assert_equal [
      0, 0,
      1, 0
    ], Twenty48::State.new([
      0, 0,
      0, 1
    ]).move(:left).to_a

    assert_equal [
      0, 0,
      1, 0
    ], Twenty48::State.new([
      0, 0,
      1, 0
    ]).move(:left).to_a

    assert_equal [
      0, 0,
      2, 0
    ], Twenty48::State.new([
      0, 0,
      1, 1
    ]).move(:left).to_a

    assert_equal [
      1, 0,
      1, 0
    ], Twenty48::State.new([
      0, 1,
      0, 1
    ]).move(:left).to_a

    assert_equal [
      2, 0,
      1, 0
    ], Twenty48::State.new([
      1, 1,
      0, 1
    ]).move(:left).to_a

    assert_equal [
      2, 0,
      2, 0
    ], Twenty48::State.new([
      1, 1,
      1, 1
    ]).move(:left).to_a
  end
end
