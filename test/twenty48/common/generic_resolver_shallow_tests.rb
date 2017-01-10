# frozen_string_literal: true

module Twenty48
  module CommonGenericResolverShallowTests
    def test_moves_to_definite_win_2x2_to_4_resolve_0
      resolver = make_resolver(2, 2, 0)
      assert_nil moves_to_win(resolver, [
        0, 0,
        0, 0
      ])

      assert_nil moves_to_win(resolver, [
        0, 0,
        0, 1
      ])

      assert_nil moves_to_win(resolver, [
        0, 0,
        1, 1
      ])

      assert_equal 0, moves_to_win(resolver, [
        0, 0,
        0, 2
      ])
    end

    def test_moves_to_definite_win_2x2_to_4_resolve_1
      resolver = make_resolver(2, 2, 1)

      assert_nil moves_to_win(resolver, [
        0, 0,
        0, 0
      ])

      assert_nil moves_to_win(resolver, [
        0, 0,
        0, 1
      ])

      assert_equal 1, moves_to_win(resolver, [
        0, 0,
        1, 1
      ])

      assert_equal 1, moves_to_win(resolver, [
        1, 0,
        1, 1
      ])

      assert_equal 1, moves_to_win(resolver, [
        1, 1,
        1, 1
      ])
    end

    def test_moves_to_definite_win_2x2_to_8_resolve_0
      resolver = make_resolver(2, 3, 0)

      assert_nil moves_to_win(resolver, [
        0, 0,
        0, 1
      ])

      assert_nil moves_to_win(resolver, [
        0, 0,
        2, 2
      ])

      assert_equal 0, moves_to_win(resolver, [
        0, 0,
        0, 3
      ])
    end

    def test_moves_to_definite_win_2x2_to_8_resolve_1
      resolver = make_resolver(2, 3, 1)

      assert_nil moves_to_win(resolver, [
        0, 0,
        0, 1
      ])

      assert_nil moves_to_win(resolver, [
        0, 0,
        1, 1
      ])

      assert_equal 1, moves_to_win(resolver, [
        0, 0,
        2, 2
      ])

      # Need two moves to win.
      assert_nil moves_to_win(resolver, [
        1, 0,
        1, 2
      ])
    end

    def test_moves_to_definite_win_3x3_to_8_resolve_1
      resolver = make_resolver(3, 3, 1)

      assert_nil moves_to_win(resolver, [
        0, 0, 0,
        0, 0, 0,
        0, 1, 1
      ])

      assert_equal 1, moves_to_win(resolver, [
        0, 0, 0,
        0, 0, 0,
        0, 2, 2
      ])

      assert_equal 1, moves_to_win(resolver, [
        0, 0, 0,
        0, 0, 0,
        2, 2, 0
      ])

      assert_equal 1, moves_to_win(resolver, [
        0, 2, 0,
        0, 2, 0,
        0, 0, 0
      ])
    end
  end
end
