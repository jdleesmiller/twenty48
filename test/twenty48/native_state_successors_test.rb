# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/state_successors_tests'

class NativeStateSuccessorsTest < Twenty48NativeTest
  include Twenty48

  # This is where most of the actual tests are defined; they call
  # #state_random_successors.
  include CommonStateSuccessorsTests

  def state_random_successors(state)
    state.random_transitions.keys
  end
end
