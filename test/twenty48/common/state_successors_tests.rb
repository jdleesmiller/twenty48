# frozen_string_literal: true

module Twenty48
  module CommonStateSuccessorsTests
    def test_random_successors_2x2
      state = make_state([0, 0, 0, 0])
      assert_states_equal [
        [0, 0, 0, 1],
        [0, 0, 0, 2],
        [0, 0, 1, 0],
        [0, 0, 2, 0],
        [0, 1, 0, 0],
        [0, 2, 0, 0],
        [1, 0, 0, 0],
        [2, 0, 0, 0]
      ], state_random_successors(state)
    end
  end
end
