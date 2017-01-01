# frozen_string_literal: true

module Twenty48
  module CommonResolverLoseTests
    def test_lose_within_2x2_to_64
      state = [
        2, 3,
        5, 3
      ]

      refute resolve_lose?(make_resolver(2, 6, 1), state)
      assert resolve_lose?(make_resolver(2, 6, 2), state)
    end

    def test_lose_within_3x3
      resolver_0 = make_resolver(3, 6, 0)
      resolver_1 = make_resolver(3, 6, 1)

      assert resolve_lose?(resolver_0, [
        1, 2, 1,
        2, 1, 2,
        1, 2, 1
      ])

      refute resolve_lose?(resolver_1, [
        0, 2, 1,
        2, 1, 2,
        1, 2, 1
      ])

      # Not sure if this is reachable, but it does serve for the test.
      assert resolve_lose?(resolver_1, [
        3, 3, 3,
        5, 1, 5,
        1, 5, 1
      ])
    end
  end
end
