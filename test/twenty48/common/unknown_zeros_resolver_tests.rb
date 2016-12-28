# frozen_string_literal: true

module Twenty48
  module CommonUnknownZerosResolverTests
    def test_incorrect_resolve_depth_3x3_to_8
      #
      # If we start from this state:
      # 0, 0, 0,
      # 0, 0, 1,
      # 1, 0, 2
      # and go left, we get
      # ?, ?, ?
      # 1, ?, ?
      # 1, 2, ?
      # Now, no matter what, we can win in two more moves (down and then left).
      # However, if the middle cell (for example) is 2^2, we can actually win in
      # one more move (down). This example imposes a limit on how many states
      # deep we can resolve and still have an exact value function. In
      # particular, we can only resolve exactly 2 moves ahead.
      #
      # Does this only apply when the max_exponent is trivially small? If the
      # max_exponent were larger, it would be harder to get one by chance. What
      # if, instead of unknown zeros, we instead used a constraint solver idea:
      # each cell starts out empty, and then after 1 move it's either 1 or 2
      # instead of just '?'. Then we could define an 'uncertain merge' rule
      # that says that if you slide a cell together with an uncertain cell,
      # the result is any one of the possible values. We're basically saying
      # at present that we never merge "?"s, which is a pessimistic assumption;
      # it just pins the known cells, but it does have this problem. It could
      # potentially let us resolve deeper, albeit at much higher cost.
      #
      state = [
        0, 0, 0,
        0, 0, 1,
        1, 0, 2
      ]

      resolver_0 = make_resolver(3, 3, 0)
      assert_nil moves_to_win(resolver_0, state)

      resolver_1 = make_resolver(3, 3, 1)
      assert_nil moves_to_win(resolver_1, state)

      resolver_2 = make_resolver(3, 3, 2)
      assert_nil moves_to_win(resolver_2, state)

      # It's possible (but not certain), that we will win in 2 moves, even
      # though we'll definitely win in 3.
      resolver_3 = make_resolver(3, 3, 3)
      assert_equal 3, moves_to_win(resolver_3, state)
    end
  end
end
