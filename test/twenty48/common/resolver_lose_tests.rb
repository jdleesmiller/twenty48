# frozen_string_literal: true

module Twenty48
  module CommonResolverLoseTests
    def test_lose_within_2x2_to_64
      resolver = make_resolver(2, 6, 2)

      state = make_state([
        2, 3,
        5, 3
      ])

      refute resolver.lose_within?(state, 1)
      assert resolver.lose_within?(state, 2)
    end

    def test_lose_within_3x3
      resolver = make_resolver(3, 6, 1)

      assert resolver.lose_within?(make_state([
        1, 2, 1,
        2, 1, 2,
        1, 2, 1
      ]), 0)

      refute resolver.lose_within?(make_state([
        0, 2, 1,
        2, 1, 2,
        1, 2, 1
      ]), 1)

      # Not sure if this is reachable, but it does serve for the test.
      assert resolver.lose_within?(make_state([
        3, 3, 3,
        5, 1, 5,
        1, 5, 1
      ]), 1)
    end
  end
end
