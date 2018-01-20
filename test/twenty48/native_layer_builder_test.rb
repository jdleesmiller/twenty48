# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerBuilderTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  def test_build_start_state_layers_2x2
    with_tmp_data do |data|
      model = data.game.new(board_size: 2, max_exponent: 8)
        .layer_model.new(max_depth: 0).mkdir!

      max_states = 1024
      layer_builder = LayerBuilder.new(model, max_states)
      layer_builder.build_start_state_layers

      # One layer part (json and vbyte) and two fragments (just vbyte)
      parts = model.part.all
      assert_equal 3, parts.size

      assert parts[0].states_vbyte.exist?
      assert_equal 0, parts[0].fragment_vbyte.count
      assert_equal 4, parts[0].sum
      assert_equal 1, parts[0].max_value
      assert_equal 2, layer_builder.count_states(4, 1)

      states_4 = parts[0].states_vbyte.read_states
      assert_states_equal [
        [0, 0,
         1, 1],
        [0, 1,
         1, 0]
      ], states_4

      assert !parts[1].states_vbyte.exist?
      assert_equal 6, parts[1].sum
      assert_equal 2, parts[1].max_value
      assert_equal 1, parts[1].fragment_vbyte.count
      assert_equal 6, parts[1].fragment_vbyte.first.input_sum # circular

      assert !parts[2].states_vbyte.exist?
      assert_equal 8, parts[2].sum
      assert_equal 2, parts[2].max_value
      assert_equal 1, parts[2].fragment_vbyte.count
      assert_equal 8, parts[2].fragment_vbyte.first.input_sum # circular

      states_6 = parts[1].fragment_vbyte.first.read_states
      states_8 = parts[2].fragment_vbyte.first.read_states

      assert_equal 2, states_4.size
      assert_equal 2, states_6.size
      assert_equal 2, states_8.size

      # The two unique states are:
      # 0 0  and  0 2
      # 2 4       4 0
      assert_states_equal [
        [0, 0,
         1, 2],
        [0, 1,
         2, 0]
      ], states_6
    end
  end

  def check_layer_part_names_to_6(names)
    assert_equal(3, names.count { |name| name.sum <= 6 })
    assert_equal 4, names[0].sum
    assert_equal 6, names[1].sum
    assert_equal 1, names[1].max_value
    assert_equal 6, names[2].sum
    assert_equal 2, names[2].max_value
  end

  def check_layer_part_names_to_8(names)
    check_layer_part_names_to_6(names)
    assert_equal(6, names.count { |name| name.sum <= 8 })
    assert_equal 8, names[3].sum
    assert_equal 1, names[3].max_value
    assert_equal 8, names[4].sum
    assert_equal 2, names[4].max_value
    assert_equal 8, names[5].sum
    assert_equal 3, names[5].max_value
  end

  def check_layer_part_names_to_8_nonempty(names)
    names = names.select { |name| name.states_vbyte.exist? }
    assert_equal 4, names.size
    assert_equal [4, 6, 6, 8], names.map(&:sum)
    assert_equal [1, 1, 2, 2], names.map(&:max_value)
  end

  def test_build_layer
    with_tmp_data do |data|
      max_states = 1024
      model = data.game.new(board_size: 2, max_exponent: 8)
        .layer_model.new(max_depth: 0).mkdir!

      layer_builder = LayerBuilder.new(model, max_states)
      layer_builder.build_start_state_layers

      #
      # Build from layer 4.
      #
      assert_equal 2, layer_builder.build_layer(4)
      assert_equal 2, layer_builder.count_states(4, 1)

      assert_states_equal [
        [0, 1,
         1, 1]
      ], model.part.find_by(sum: 6, max_value: 1).states_vbyte.read_states
      assert_equal 1, layer_builder.count_states(6, 1)

      assert_states_equal [
        [0, 0,
         1, 2],
        [0, 1,
         2, 0]
      ], model.part.find_by(sum: 6, max_value: 2).states_vbyte.read_states
      assert_equal 2, layer_builder.count_states(6, 2)

      check_layer_part_names_to_6(model.part.all)

      #
      # Build from layer 6.
      #
      layer_builder.build_layer(6)

      check_layer_part_names_to_8(model.part.all)
      assert_states_equal [],
        model.part.find_by(sum: 8, max_value: 1).states_vbyte.read_states
      assert_equal 0, layer_builder.count_states(8, 1)
      assert_equal 4,
        model.part.find_by(sum: 8, max_value: 2).states_vbyte.read_states.size
      assert_equal 4, layer_builder.count_states(8, 2)
      assert_states_equal [],
        model.part.find_by(sum: 8, max_value: 3).states_vbyte.read_states
      assert_equal 0, layer_builder.count_states(8, 3)

      #
      # Test cleanup.
      #
      layer_builder.remove_empty_layer_parts(8)

      check_layer_part_names_to_8_nonempty(model.part.all)
    end
  end

  def test_build_and_solve_2x2_to_128
    with_tmp_data do |data|
      max_states = 4
      model = data.game.new(board_size: 2, max_exponent: 7)
        .layer_model.new(max_depth: 0).mkdir!

      layer_builder = LayerBuilder.new(model, max_states)
      layer_builder.build_start_state_layers
      layer_builder.build

      part_names = model.part.all
      assert_equal 24, part_names.map(&:sum).uniq.size
      assert_equal(74, part_names.map do |part|
        part.states_vbyte.read_states.size
      end.inject(:+))

      layer_solver = LayerSolver.new(model, discount: DISCOUNT)
      layer_solver.solve

      part_4_1 = model.part.find_by(sum: 4, max_value: 1)
      values_4_file = part_4_1.solution.first.values
      assert_equal 32, File.size(values_4_file.to_s)

      # This game is not winnable.
      state_values = values_4_file.read_state_values
      assert_equal 0, state_values[0][1]
      assert_equal 0, state_values[1][1]
    end
  end

  def test_build_and_solve_2x2_to_32
    with_tmp_data do |data|
      max_states = 4
      model = data.game.new(board_size: 2, max_exponent: 5)
        .layer_model.new(max_depth: 0).mkdir!

      layer_builder = LayerBuilder.new(model, max_states)
      layer_builder.build_start_state_layers
      layer_builder.build

      part_names = model.part.all
      assert_equal 18, part_names.map(&:sum).uniq.size
      assert_equal(57, part_names.map do |part|
        part.states_vbyte.read_states.size
      end.inject(:+))

      layer_solver = LayerSolver.new(model, discount: DISCOUNT)
      layer_solver.solve

      part_4_1 = model.part.find_by(sum: 4, max_value: 1)
      values_4_file = part_4_1.solution.first.values
      assert_equal 32, File.size(values_4_file.to_s)

      # This game is quite hard to win.
      state_values = values_4_file.read_state_values
      assert_close 0.03831963657896261, state_values[0][1]
      assert_close 0.03831963657896261, state_values[1][1]
    end
  end
end
