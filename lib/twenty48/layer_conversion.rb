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
      layer_part_names = LayerPartName.glob(states_folder)
      policy_part_names = LayerPartPolicyName.glob(policy_folder)

      if layer_part_names.size != policy_part_names.size
        raise 'state / policy size mismatch'
      end

      lose_state = State.new([0] * board_size**2)
      win_state = State.new([0] * (board_size**2 - 1) + [max_exponent])
      rows = [
        [lose_state, :down, lose_state, 1.0, 0.0],
        [win_state, :up, win_state, 1.0, 1.0 - discount]
      ]

      layer_part_names.zip(policy_part_names).each do |layer_name, policy_name|
        states = layer_name.read_states(board_size, folder: states_folder)
        policy = PolicyReader.read(policy_name.in(policy_folder), states.size)
        states.zip(policy).each do |state, action|
          move_state = state.move(action)
          move_state.random_transitions.each do |successor, pr|
            successor = State.new(successor.to_a)
            if successor.win?(max_exponent)
              successor = win_state
            elsif successor.lose?
              successor = lose_state
            end
            rows << [
              State.new(state.to_a), DIRECTIONS[action], successor, pr, 0.0
            ]
          end
        end
      end

      # We can end up with multiple transitions to the same state; handle that
      # here by merging together such rows.
      rows = rows.group_by { |row| row[0...3] }.map do |sas, sas_rows|
        total_pr = sas_rows.map { |_, _, _, pr, _| pr }.sum
        max_reward = sas_rows.map { |_, _, _, _, reward| reward }.max
        sas + [total_pr, max_reward]
      end

      FiniteMDP::TableModel.new(rows)
    end
  end
end
