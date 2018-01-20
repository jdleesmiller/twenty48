# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerQSolverTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  def test_solve_2x2
    with_tmp_data do |data|
      run_q_solve(data, 4)
    end
  end

  def test_solve_2x2_with_alternate_actions
    with_tmp_data do |data|
      model, solution_attributes = run_q_solve(
        data, 16,
        alternate_action_tolerance: 1e-6,
        save_all_values: true
      )

      q = {}
      alternate_action_names = []
      model.part.each do |part|
        solution = part.solution.find_by(solution_attributes)
        solution.fragment.each do |fragment|
          next unless fragment.values_csv.exist?
          CSV.foreach(fragment.values_csv.to_s) do |state, *q_values|
            q[state] = q_values.map do |value|
              value == '-inf' ? -Float::INFINITY : value.to_f
            end
          end
        end
        if solution.alternate_actions.exist?
          alternate_action_names << solution.alternate_actions
        end
      end
      assert_equal 25, alternate_action_names.size

      model.part.each do |part|
        info = part.info_json.read
        states = part.states_vbyte.read_states

        solution = part.solution.find_by(solution_attributes)
        policy_reader = PolicyReader.new(solution.policy.to_s)
        actions = AlternateActionReader.read(
          solution.alternate_actions.to_s, policy_reader, info['num_states']
        )

        states.zip(actions).each do |state, alternate_actions|
          qs = q[state.get_nybbles.to_s(16)]
          q_max = qs.max
          max_q_actions = qs.map { |q_value| q_value > q_max - 1e-6 }
          assert_equal max_q_actions, alternate_actions
        end
      end
    end
  end

  def run_q_solve(data, batch_size, solver_options = {})
    save_all_values = solver_options.delete(:save_all_values)
    solver_options[:discount] = DISCOUNT

    model = data.game.new(board_size: 2, max_exponent: 5)
      .layer_model.new(max_depth: 0).mkdir!
    layer_builder = LayerBuilder.new(model, batch_size)
    layer_builder.build_start_state_layers
    layer_builder.build

    part_names = model.part.all
    assert_equal 18, part_names.map(&:sum).uniq.size

    layer_solver = LayerQSolver.new(model, solver_options)
    layer_solver.save_all_values = true if save_all_values
    layer_solver.solve

    assert_close 0.03868113,
      LayerStartStates.find_mean_start_state_value(
        model, layer_solver.solution_attributes
      )

    [model, layer_solver.solution_attributes]
  end
end
