# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerCompactorTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  def test_build_2x2
    Dir.mktmpdir do |tmp|
      states_path = File.join(tmp, 'states')
      values_path = File.join(tmp, 'values')
      compacted_path = File.join(tmp, 'compacted')

      [states_path, values_path, compacted_path].each do |path|
        FileUtils.mkdir_p path
      end

      max_states = 4
      max_exponent = 5
      board_size = 2
      valuer = NativeValuer.create(
        board_size: board_size,
        max_exponent: max_exponent,
        max_depth: 0,
        discount: DISCOUNT
      )
      layer_builder = LayerBuilder.new(2, states_path, max_states, valuer)
      layer_builder.build_start_state_layers
      layer_builder.build

      part_names = LayerPartName.glob(states_path)
      assert_equal 18, part_names.map(&:sum).uniq.size

      layer_solver = LayerSolver.new(
        2,
        states_path,
        values_path,
        valuer
      )
      layer_solver.solve

      # 2 states at 16B / state
      values_4_file = LayerPartValuesName.glob(values_path)
        .find { |name| name.sum == 4 && name.max_value == 1 }
      assert_equal 32, File.size(values_4_file.in(values_path))

      # Run the compactor.
      layer_compactor = LayerCompactor.new(
        2, states_path, max_states, valuer,
        values_path, compacted_path
      )
      layer_compactor.build_start_state_layers
      layer_compactor.build

      # With discount factor set to 0.95, it will remove some states from
      # sum 10 / max value 3 and sum 12 / max value 3. If the discount
      # factor is 0.99, then it won't.

      # Check the subset policy is consistent with the original.
      original_values = {}
      LayerPartName.glob(states_path).each do |name|
        policy = LayerPartPolicyName.new(
          sum: name.sum, max_value: name.max_value
        )
        original_states = name.read_states(board_size, folder: states_path)
        original_policy = PolicyReader.read(
          policy.in(values_path), original_states.size
        )
        compacted_states = name.read_states(board_size, folder: compacted_path)
        compacted_policy = PolicyReader.read(
          policy.in(compacted_path), compacted_states.size
        )

        assert original_states.size >= compacted_states.size
        assert_equal original_states.size, original_policy.size
        assert_equal compacted_states.size, compacted_policy.size

        original_states.each.with_index do |original_state, original_index|
          compacted_index = compacted_states.index(original_state)
          next unless compacted_index
          assert_equal original_policy[original_index],
            compacted_policy[compacted_index]
        end

        LayerPartValuesName.new(
          sum: name.sum, max_value: name.max_value
        ).read(board_size, folder: values_path).each do |state, value|
          original_values[State.new(state.to_a)] = value
        end
      end

      # Check that the values of all states are also consistent.
      original_model =
        LayerConversion.convert_layers_to_finite_mdp_model_with_policy(
          board_size, max_exponent, DISCOUNT, states_path, values_path
        )
      original_solver = FiniteMDP::Solver.new(original_model, DISCOUNT)
      original_solver.policy_iteration_exact

      # This model will only have one action per state, but we can still 'solve'
      # it in the same way.
      compacted_model =
        LayerConversion.convert_layers_to_finite_mdp_model_with_policy(
          board_size, max_exponent, DISCOUNT, compacted_path, compacted_path
        )
      compacted_solver = FiniteMDP::Solver.new(compacted_model, DISCOUNT)
      compacted_solver.policy_iteration_exact

      compacted_values = compacted_solver.value
      original_solver.value.each do |original_state, original_value|
        compacted_value = compacted_values[original_state]
        next unless compacted_value
        assert_equal original_value, compacted_value
        next unless original_values.key?(original_state)
        assert_close original_values[original_state], compacted_value
      end
    end
  end
end
