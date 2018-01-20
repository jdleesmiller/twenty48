# frozen_string_literal: true

require 'csv'
require 'json'

require 'key_value_name'

module Twenty48
  #
  # Build array models
  #
  module ArrayModelBuilder
    include Storage

    def find_state_index(states, state)
      (0...states.size).bsearch { |i| states[i] >= state }
    end

    def build_array_model(hash_json_bz2)
      # Read in all states and sort them so we know their state numbers.
      states = hash_json_bz2.read_states.sort

      # Then read them in again, one at a time to keep memory under control.
      array = Array.new(states.size)
      state_action_map = Array.new(states.size)
      hash_json_bz2.each_model_state_actions do |state, actions|
        state_array = actions.map do |_action, successors|
          successors.map do |successor, (probability, reward)|
            [find_state_index(states, successor), probability, reward]
          end
        end

        state_index = find_state_index(states, state)
        state_action_map[state_index] = [state, actions.keys]
        array[state_index] = state_array
      end

      FiniteMDP::ArrayModel.new(
        array,
        FiniteMDP::ArrayModel::OrderedStateActionMap.new(state_action_map)
      )
    end
  end
end
