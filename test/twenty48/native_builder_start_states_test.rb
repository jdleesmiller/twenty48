# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/builder_start_states'

class NativeBuilderStartStatesTest < Twenty48NativeTest
  include Twenty48

  # Some of the tests are defined here; they call #builder_start_states.
  include CommonBuilderStartStatesTests

  def make_builder(size, max_exponent)
    case size
    when 2 then return Builder2.new(max_exponent)
    when 3 then return Buidler3.new(max_exponent)
    when 4 then return Builder4.new(max_exponent)
    end
    raise "bad builder size: #{size}"
  end

  def builder_start_states(builder)
    builder.generate_start_states
  end
end
