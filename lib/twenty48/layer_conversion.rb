# frozen_string_literal: true

module Twenty48
  #
  # Utilities for converting the layer representation to the in-memory
  # representation. This is only suitable for small models.
  #
  module LayerConversion
    module_function

    def initialize_finite_mdp_hash_model
      Hash.new do |h1, state|
        h1[state] = Hash.new do |h2, action|
          h2[action] = Hash.new do |h3, successor|
            h3[successor] = [0.0, 0.0]
          end
        end
      end
    end

    def add_lose_win_states(
      model, board_size, max_exponent, absorbing_win, reward
    )
      lose_state = State.new([0] * board_size**2)
      win_state = State.new([0] * (board_size**2 - 1) + [max_exponent])

      model[lose_state][:down][lose_state] = [1.0, 0.0]
      win_reward = absorbing_win ? reward : 0.0
      model[win_state][:up][win_state] = [1.0, win_reward]

      [lose_state, win_state]
    end

    def build_finite_mdp_hash_by_part(layer_model,
      reward: 1.0, absorbing_win: true)
      max_exponent = layer_model.max_exponent

      model = initialize_finite_mdp_hash_model
      lose_state, win_state = add_lose_win_states(
        model, layer_model.board_size, max_exponent, absorbing_win, reward
      )

      layer_model.part.each do |part|
        yield(part).each do |native_state, actions|
          state = State.new(native_state.to_a)
          actions.each do |action|
            move_state = native_state.move(action)
            if move_state.max_value >= max_exponent
              win_reward = absorbing_win ? 0.0 : reward
              model[state][DIRECTIONS[action]][win_state] = [1.0, win_reward]
              next
            end
            move_state.random_transitions.each do |native_successor, pr|
              successor = State.new(native_successor.to_a)
              successor = lose_state if successor.lose?
              model[state][DIRECTIONS[action]][successor][0] += pr
            end
          end
        end
      end
      make_hash_model(model)
    end

    def make_hash_model(model)
      hash_model = FiniteMDP::HashModel.new(model)
      hash_model.check_transition_probabilities_sum
      hash_model
    end

    def convert_layers_to_finite_mdp_model(layer_model)
      build_finite_mdp_hash_by_part(layer_model, absorbing_win: false) do |part|
        part.states_vbyte.read_states.map do |native_state|
          actions = (0..3).map do |action|
            action if native_state.move(action) != native_state
          end.compact
          [native_state, actions]
        end
      end
    end

    #
    # Convert a layer model into a ruby FiniteMDP::Model.
    #
    def convert_layers_to_finite_mdp_model_with_policy(
      layer_model, solution_attributes
    )
      reward = 1.0 - solution_attributes[:discount]

      build_finite_mdp_hash_by_part(layer_model, reward: reward) do |part|
        states = part.states_vbyte.read_states
        solution = part.solution.find_by(solution_attributes)
        policy = PolicyReader.read(solution.policy.to_s, states.size)
        states.zip(policy).map do |native_state, action|
          [native_state, [action]]
        end
      end
    end
  end
end
