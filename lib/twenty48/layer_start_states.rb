# frozen_string_literal: true

require 'parallel'
require 'tmpdir'

module Twenty48
  #
  # Utilities for dealing with start states in layers.
  #
  module LayerStartStates
    module_function

    #
    # @param [LayerStateProbabilities] probabilities
    #
    def find_start_state_probabilities(board_size, probabilities)
      empty_state = NativeState.create([0] * board_size**2)
      empty_state.random_transitions.each do |one_tile_state, pr0|
        one_tile_state.random_transitions.each do |two_tile_state, pr1|
          probabilities.add(two_tile_state, pr0 * pr1)
        end
      end
    end

    def find_mean_start_state_value(board_size, folder)
      start_state_weights = LayerStateProbabilities.new
      find_start_state_probabilities(board_size, start_state_weights)

      mean_value = 0.0
      start_state_weights.each_sum_max_value do |sum, max_value, weights|
        name = LayerPartValuesName.new(sum: sum, max_value: max_value)
        name.read(board_size, folder: folder).each do |state, value|
          next unless weights.key?(state.get_nybbles)
          mean_value += weights[state.get_nybbles] * value
        end
      end

      mean_value
    end
  end
end
