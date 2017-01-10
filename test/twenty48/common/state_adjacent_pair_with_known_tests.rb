# frozen_string_literal: true

module Twenty48
  module CommonStateAdjacentPairWithKnownTests
    def test_adjacent_pairs_with_knowns
      state = make_state([
        0, 1,
        1, 1
      ])
      assert state.adjacent_pair?(1)
      refute state.adjacent_pair?(2)

      state = make_state([
        0, 1,
        1, 2
      ])
      refute state.adjacent_pair?(1)
      refute state.adjacent_pair?(2)

      state = make_state([
        0, 2,
        1, 2
      ])
      refute state.adjacent_pair?(1)
      assert state.adjacent_pair?(2)

      state = make_state([
        0, 1,
        2, 2
      ])
      refute state.adjacent_pair?(1)
      assert state.adjacent_pair?(2)

      state = make_state([
        1, 0, 1,
        0, 0, 0,
        0, 0, 0
      ])
      assert state.adjacent_pair?(1)

      state = make_state([
        1, 0, 0,
        0, 0, 0,
        1, 0, 0
      ])
      assert state.adjacent_pair?(1)

      state = make_state([
        0, 1, 1,
        0, 0, 0,
        0, 0, 0
      ])
      assert state.adjacent_pair?(1)

      state = make_state([
        1, 0, 0,
        1, 0, 0,
        0, 0, 0
      ])
      assert state.adjacent_pair?(1)

      state = make_state([
        0, 0, 0, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
      ])
      assert state.adjacent_pair?(1)
    end
  end
end
