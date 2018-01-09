# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerQSolverTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  def test_solve_2x2
    Dir.mktmpdir do |tmp|
      run_q_solve(tmp, 4)
    end
  end

  def test_solve_2x2_with_alternate_actions
    Dir.mktmpdir do |tmp|
      states_folder, values_folder = run_q_solve(
        tmp, 16,
        alternate_action_tolerance: 1e-6,
        save_all_values: true
      )

      q = {}
      Dir.glob(File.join(values_folder, '*.all.csv')).each do |all_csv|
        CSV.foreach(all_csv) do |state, *q_values|
          q[state] = q_values.map do |value|
            value == '-inf' ? -Float::INFINITY : value.to_f
          end
        end
      end

      alternate_action_names = LayerPartAlternateActionName.glob(values_folder)
      assert_equal 25, alternate_action_names.size
      alternate_action_names.each do |actions|
        info = LayerPartInfoName.new(
          sum: actions.sum, max_value: actions.max_value
        ).read(folder: states_folder)
        states = Twenty48.read_states_vbyte(2, LayerPartName.new(
          sum: actions.sum, max_value: actions.max_value
        ).in(states_folder))
        policy_pathname = LayerPartPolicyName.new(
          sum: actions.sum, max_value: actions.max_value
        ).in(values_folder)
        policy_reader = PolicyReader.new(policy_pathname)
        actions = AlternateActionReader.read(
          actions.in(values_folder), policy_reader, info['num_states']
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

  def run_q_solve(tmp, batch_size, solver_options = {})
    save_all_values = solver_options.delete(:save_all_values)

    states_folder = File.join(tmp, 'states')
    values_folder = File.join(tmp, 'values')

    [states_folder, values_folder].each { |path| FileUtils.mkdir_p(path) }

    max_exponent = 5
    board_size = 2
    params = {
      board_size: board_size,
      max_exponent: max_exponent,
      max_depth: 0,
      discount: DISCOUNT
    }
    valuer = NativeValuer.create(params)
    layer_builder = LayerBuilder.new(2, states_folder, batch_size, valuer)
    layer_builder.build_start_state_layers
    layer_builder.build

    part_names = LayerPartName.glob(states_folder)
    assert_equal 18, part_names.map(&:sum).uniq.size

    layer_solver = LayerQSolver.new(
      2,
      states_folder,
      values_folder,
      valuer,
      solver_options
    )
    layer_solver.save_all_values = true if save_all_values
    layer_solver.solve

    assert_close 0.03868113,
      LayerStartStates.find_mean_start_state_value(board_size, values_folder)

    [states_folder, values_folder]
  end
end
