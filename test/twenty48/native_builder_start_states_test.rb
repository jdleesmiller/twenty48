# frozen_string_literal: true

require_relative 'helper'

class NativeBuilderStartStateTest < Twenty48NativeTest
  def test_start_states_2x2
    builder = Twenty48::Builder2.new(3)
    builder.open_start_states
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
    ], builder.open_states
  end
end
