# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../../lib/twenty_48'

class Twenty48Test < Minitest::Test
  def assert_close(x, y)
    assert_in_delta x, y, 1e-6
  end

  def make_states(state_arrays)
    state_arrays.map { |state_array| Twenty48::State.new(state_array) }
  end

  def assert_states_equal(expected_state_arrays, observed_states)
    assert_equal make_states(expected_state_arrays), observed_states
  end

  def build_hash_model(builder)
    hash = {}
    builder.build do |state, state_hash|
      hash[state] = state_hash
    end
    hash
  end
end
