# frozen_string_literal: true

module Twenty48
  module CommonStateAdjacentPairWithUnknownTests
    def test_adjacent_pairs_with_unknowns
      state = make_state([
        0, 1,
        1, 1
      ])
      assert state.adjacent_pair?(1, true)
      refute state.adjacent_pair?(2, true)

      state = make_state([
        0, 1,
        1, 2
      ])
      refute state.adjacent_pair?(1, true)
      refute state.adjacent_pair?(2, true)

      state = make_state([
        0, 2,
        1, 2
      ])
      refute state.adjacent_pair?(1, true)
      assert state.adjacent_pair?(2, true)

      state = make_state([
        0, 1,
        2, 2
      ])
      refute state.adjacent_pair?(1, true)
      assert state.adjacent_pair?(2, true)

      state = make_state([
        1, 0, 1,
        0, 0, 0,
        0, 0, 0
      ])
      refute state.adjacent_pair?(1, true)

      state = make_state([
        1, 0, 0,
        0, 0, 0,
        1, 0, 0
      ])
      refute state.adjacent_pair?(1, true)

      state = make_state([
        0, 1, 1,
        0, 0, 0,
        0, 0, 0
      ])
      assert state.adjacent_pair?(1, true)

      state = make_state([
        1, 0, 0,
        1, 0, 0,
        0, 0, 0
      ])
      assert state.adjacent_pair?(1, true)

      state = make_state([
        0, 0, 0, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
      ])
      assert state.adjacent_pair?(1, true)
    end
  end
end
