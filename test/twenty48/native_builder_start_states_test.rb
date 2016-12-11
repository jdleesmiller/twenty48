# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/builder_start_states'

class NativeBuilderStartStatesTest < Twenty48NativeTest
  include Twenty48

  # Some of the tests are defined here; they call #builder_start_states.
  include CommonBuilderStartStatesTests

  def builder_start_states(builder)
    builder.generate_start_states
  end
end
