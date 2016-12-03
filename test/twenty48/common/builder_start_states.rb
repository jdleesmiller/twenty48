# frozen_string_literal: true

module Twenty48
  module CommonBuilderStartStatesTests
    def test_start_states_2x2
      builder = make_builder(2, 3)
      assert_states_equal [
        [0, 0,
         1, 1],
        [0, 0,
         1, 2],
        [0, 0,
         2, 2],
        [0, 1,
         1, 0],
        [0, 1,
         2, 0],
        [0, 2,
         2, 0]
      ], builder_start_states(builder)
    end
  end
end
