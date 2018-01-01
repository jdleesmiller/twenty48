# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerQSolverTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  def test_solve_2x2
    Dir.mktmpdir do |tmp|
      states_folder = File.join(tmp, 'states')
      values_folder = File.join(tmp, 'values')

      [states_folder, values_folder].each { |path| FileUtils.mkdir_p(path) }

      max_states = 4
      max_exponent = 5
      board_size = 2
      params = {
        board_size: board_size,
        max_exponent: max_exponent,
        max_depth: 0,
        discount: DISCOUNT
      }
      valuer = NativeValuer.create(params)
      layer_builder = LayerBuilder.new(2, states_folder, max_states, valuer)
      layer_builder.build_start_state_layers
      layer_builder.build

      part_names = LayerPartName.glob(states_folder)
      assert_equal 18, part_names.map(&:sum).uniq.size

      layer_solver = LayerQSolver.new(
        2,
        states_folder,
        values_folder,
        valuer
      )
      layer_solver.solve

      assert_close 0.03868113,
        LayerStartStates.find_mean_start_state_value(board_size, values_folder)
    end
  end
end
