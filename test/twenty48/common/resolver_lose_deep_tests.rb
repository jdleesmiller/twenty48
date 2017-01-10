# frozen_string_literal: true

module Twenty48
  module CommonResolverLoseDeepTests
    def test_lose_within_2x2_to_64
      state = [
        2, 3,
        5, 3
      ]

      refute resolve_lose?(make_resolver(2, 6, 0), state)
      refute resolve_lose?(make_resolver(2, 6, 1), state)
      assert resolve_lose?(make_resolver(2, 6, 2), state)
    end
  end
end
