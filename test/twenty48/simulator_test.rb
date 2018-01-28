# frozen_string_literal: true

require_relative 'helper'

class SimulatorTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.99

  def test_sim_2x2
    with_tmp_data do |data|
      max_states = 16
      model = data.game.new(board_size: 2, max_exponent: 5)
        .layer_model.new(max_depth: 0).mkdir!

      layer_builder = LayerBuilder.new(model, max_states)
      layer_builder.build_start_state_layers
      layer_builder.build

      layer_solver = LayerSolver.new(model, discount: DISCOUNT)
      layer_solver.solve

      simulator = Simulator.new(
        model, layer_solver.solution_attributes, 100, Random.new(2)
      )
      simulator.run

      # just make sure it runs
    end
  end
end
