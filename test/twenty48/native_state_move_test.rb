# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/state_move_tests'

class NativeStateMoveTest < Twenty48NativeTest
  include Twenty48

  # This is where the actual tests are defined; they call #move_state.
  include CommonStateMoveTests

  def move_state(state_array, direction)
    direction_number = case direction
                       when :left then DIRECTION_LEFT
                       when :right then DIRECTION_RIGHT
                       when :up then DIRECTION_UP
                       when :down then DIRECTION_DOWN
                       end
    make_state(state_array).move(direction_number).to_a
  end
end
