# frozen_string_literal: true

module Twenty48
  module CommonGenericResolverDeepTests
    def test_moves_to_definite_win_2x2_to_8_resolve_2
      resolver = make_resolver(2, 3, 2)

      assert_nil moves_to_win(resolver, [
        0, 0,
        1, 1
      ])

      assert_nil moves_to_win(resolver, [
        0, 0,
        1, 2
      ])

      assert_nil moves_to_win(resolver, [
        0, 1,
        1, 2
      ])

      assert_equal 1, moves_to_win(resolver, [
        0, 0,
        2, 2
      ])

      assert_equal 1, moves_to_win(resolver, [
        1, 1,
        2, 2
      ])

      assert_equal 1, moves_to_win(resolver, [
        1, 2,
        2, 2
      ])

      assert_equal 2, moves_to_win(resolver, [
        1, 0,
        1, 2
      ])

      assert_equal 2, moves_to_win(resolver, [
        1, 1,
        1, 2
      ])
    end

    def test_moves_to_definite_win_2x2_to_16_resolve_2
      resolver = make_resolver(2, 4, 2)

      assert_nil moves_to_win(resolver, [
        1, 1,
        2, 3
      ])
    end

    def test_moves_to_definite_win_2x2_to_16_resolve_3
      resolver = make_resolver(2, 4, 3)

      assert_equal 3, moves_to_win(resolver, [
        1, 1,
        2, 3
      ])

      # This state actually presents an interesting choice:
      # - if you go left, you can win in 4 moves with probability 0.9
      # - if you go up, you can win in 3 moves with probability 0.1
      # With a resolve depth of 3, going left has unknown value, even though
      # it's better than going up, which has a known value.
      assert_nil moves_to_win(resolver, [
        0, 1,
        2, 3
      ])
    end

    def test_moves_to_definite_win_3x3_to_8_resolve_2
      resolver = make_resolver(3, 3, 2)

      assert_equal 2, moves_to_win(resolver, [
        0, 0, 0,
        0, 0, 0,
        1, 1, 2
      ])

      assert_equal 2, moves_to_win(resolver, [
        0, 0, 0,
        1, 0, 0,
        1, 2, 0
      ])

      assert_equal 2, moves_to_win(resolver, [
        1, 0, 0,
        1, 0, 0,
        2, 0, 0
      ])

      assert_equal 2, moves_to_win(resolver, [
        0, 0, 0,
        0, 1, 0,
        0, 1, 2
      ])

      assert_equal 2, moves_to_win(resolver, [
        0, 0, 0,
        1, 1, 0,
        0, 2, 0
      ])

      assert_nil moves_to_win(resolver, [
        0, 0, 0,
        1, 0, 0,
        1, 0, 2
      ])
    end

    def test_moves_to_definite_win_3x3_to_16_resolve_2
      resolver = make_resolver(3, 4, 2)

      assert_nil moves_to_win(resolver, [
        0, 0, 0,
        1, 1, 3,
        0, 2, 0
      ])
    end

    def test_moves_to_definite_win_4x4_to_8_resolve_2
      resolver = make_resolver(4, 3, 2)

      #
      # If we move right, we end up with two adjacent 2s, but the exact state
      # after moving up or down in that position is unknown. We can however tell
      # that it's a win. This tripped up an earlier version of the heuristic.
      #
      assert_equal 2, moves_to_win(resolver, [
        0, 0, 0, 0,
        0, 0, 0, 2,
        0, 2, 0, 0,
        0, 0, 0, 0
      ])
    end
  end
end
