# frozen_string_literal: true

module Twenty48
  module CommonResolverLoseShallowTests
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
