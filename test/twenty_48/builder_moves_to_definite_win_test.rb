# frozen_string_literal: true

require_relative 'helper'

class BuilderMovesToDefiniteWinTest < Twenty48Test
  include Twenty48

  def test_moves_to_definite_win_2x2_to_4_resolve_0
    builder = Builder.new(2, 2)

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      0, 0
    ]))

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      0, 1
    ]))

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      1, 1
    ]))

    assert_equal 0, builder.moves_to_definite_win(State.new([
      0, 0,
      0, 2
    ]))
  end

  def test_moves_to_definite_win_2x2_to_4_resolve_1
    builder = Builder.new(2, 2, 1)

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      0, 0
    ]))

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      0, 1
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      0, 0,
      1, 1
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      1, 0,
      1, 1
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      1, 1,
      1, 1
    ]))
  end

  def test_moves_to_definite_win_2x2_to_8_resolve_0
    builder = Builder.new(2, 3)

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      0, 1
    ]))

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      2, 2
    ]))

    assert_equal 0, builder.moves_to_definite_win(State.new([
      0, 0,
      0, 3
    ]))
  end

  def test_moves_to_definite_win_2x2_to_8_resolve_1
    builder = Builder.new(2, 3, 1)

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      0, 1
    ]))

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      1, 1
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      0, 0,
      2, 2
    ]))

    # Need two moves to win.
    assert_nil builder.moves_to_definite_win(State.new([
      1, 0,
      1, 2
    ]))
  end

  def test_moves_to_definite_win_2x2_to_8_resolve_2
    builder = Builder.new(2, 3, 2)

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      1, 1
    ]))

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0,
      1, 2
    ]))

    assert_nil builder.moves_to_definite_win(State.new([
      0, 1,
      1, 2
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      0, 0,
      2, 2
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      1, 1,
      2, 2
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      1, 2,
      2, 2
    ]))

    assert_equal 2, builder.moves_to_definite_win(State.new([
      1, 0,
      1, 2
    ]))

    assert_equal 2, builder.moves_to_definite_win(State.new([
      1, 1,
      1, 2
    ]))
  end

  def test_moves_to_definite_win_2x2_to_16_resolve_2
    builder = Builder.new(2, 4, 2)

    assert_nil builder.moves_to_definite_win(State.new([
      1, 1,
      2, 3
    ]))
  end

  def test_moves_to_definite_win_2x2_to_16_resolve_3
    builder = Builder.new(2, 4, 3)

    assert_equal 3, builder.moves_to_definite_win(State.new([
      1, 1,
      2, 3
    ]))
  end

  def test_moves_to_definite_win_3x3_to_8_resolve_1
    builder = Builder.new(3, 3, 1)

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0, 0,
      0, 0, 0,
      0, 1, 1
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      0, 0, 0,
      0, 0, 0,
      0, 2, 2
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      0, 0, 0,
      0, 0, 0,
      2, 2, 0
    ]))

    assert_equal 1, builder.moves_to_definite_win(State.new([
      0, 2, 0,
      0, 2, 0,
      0, 0, 0
    ]))
  end

  def test_moves_to_definite_win_3x3_to_8_resolve_2
    builder = Builder.new(3, 3, 2)

    assert_equal 2, builder.moves_to_definite_win(State.new([
      0, 0, 0,
      0, 0, 0,
      1, 1, 2
    ]))

    assert_equal 2, builder.moves_to_definite_win(State.new([
      0, 0, 0,
      1, 0, 0,
      1, 2, 0
    ]))

    assert_equal 2, builder.moves_to_definite_win(State.new([
      1, 0, 0,
      1, 0, 0,
      2, 0, 0
    ]))

    assert_equal 2, builder.moves_to_definite_win(State.new([
      0, 0, 0,
      0, 1, 0,
      0, 1, 2
    ]))

    assert_equal 2, builder.moves_to_definite_win(State.new([
      0, 0, 0,
      1, 1, 0,
      0, 2, 0
    ]))

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0, 0,
      1, 0, 0,
      1, 0, 2
    ]))
  end

  def test_moves_to_definite_win_3x3_to_16_resolve_2
    builder = Builder.new(3, 4, 2)

    assert_nil builder.moves_to_definite_win(State.new([
      0, 0, 0,
      1, 1, 3,
      0, 2, 0
    ]))
  end

  def test_moves_to_definite_win_4x4_to_16_resolve_3
    builder = Twenty48::Builder.new(4, 4, 3)

    assert_nil builder.moves_to_definite_win(Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 0,
      2, 0, 0, 3,
      2, 1, 2, 1
    ]))

    assert_equal 1, builder.moves_to_definite_win(Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 1,
      3, 0, 0, 0,
      3, 0, 0, 0
    ]))

    assert_equal 2, builder.moves_to_definite_win(Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 0,
      2, 0, 0, 2,
      0, 0, 0, 3
    ]))

    #
    # This state is tricky. It is actually possible to win, but you have to
    # consider an "either or" argument. From
    #
    #    .    .    .    .
    #    .    .    .    2
    #    4    2    4    8
    #    .    4    2    4
    #
    # Go left. If the new tile is on the top line, you get a state like this,
    # and you can easily win in two (down and right).
    #
    #    .    .    .    2
    #    .    .    .    2
    #    8    4    2    4
    #    .    4    2    4
    #
    # However, if the new tile is in the corner below the 8, you get a state
    # like this one:
    #
    #    .    .    .    .
    #    .    .    .    2
    #    8    4    2    4
    #    2    4    2    4
    #
    # From there, you win in two by going up and right. This is beyond what the
    # heuristic can do.
    #
    assert_nil builder.moves_to_definite_win(Twenty48::State.new([
      0, 0, 0, 0,
      0, 0, 0, 1,
      2, 1, 2, 3,
      0, 2, 1, 2
    ]))
  end
end
