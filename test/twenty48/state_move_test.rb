# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../../lib/twenty48'
require_relative 'helper'
require_relative 'common/state_move_tests'

class StateMoveTest < Twenty48Test
  include Twenty48

  # This is where the actual tests are defined; they call #move_state.
  include CommonStateMoveTests

  def move_state(state_array, direction)
    make_state(state_array).move(direction).to_a
  end
end
