# frozen_string_literal: true

module Twenty48
  #
  # Utilities for converting the layer representation to the in-memory
  # representation. This is only suitable for small models.
  #
  module LayerConversion
    module_function

    #
    # Convert a layer model into a ruby FiniteMDP::Model.
    #
    def convert_layers_to_finite_mdp_model_with_policy(
      board_size, max_exponent, discount, states_folder, policy_folder
    )
      lose_state = State.new([0] * board_size**2)
      win_state = State.new([0] * (board_size**2 - 1) + [max_exponent])

      model = Hash.new do |h1, state|
        h1[state] = Hash.new do |h2, action|
          h2[action] = Hash.new do |h3, successor|
            h3[successor] = [0.0, 0.0]
          end
        end
      end

      model[lose_state][:down][lose_state] = [1.0, 0.0]
      model[win_state][:down][win_state] = [1.0, 1.0 - discount]

      LayerPartName.glob(states_folder).each do |part|
        states = part.read_states(board_size, folder: states_folder)
        policy = PolicyReader.read(LayerPartPolicyName.new(
          sum: part.sum, max_value: part.max_value
        ).in(policy_folder), states.size)
        states.zip(policy).each do |native_state, action|
          state = State.new(native_state.to_a)
          move_state = native_state.move(action)
          move_state.random_transitions.each do |native_successor, pr|
            successor = State.new(native_successor.to_a)
            if successor.win?(max_exponent)
              successor = win_state
            elsif successor.lose?
              successor = lose_state
            end
            model[state][DIRECTIONS[action]][successor][0] += pr
          end
        end
      end

      hash_model = FiniteMDP::HashModel.new(model)
      hash_model.check_transition_probabilities_sum
      hash_model
    end
  end
end
