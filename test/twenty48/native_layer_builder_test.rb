# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerBuilderTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  def test_build_start_state_layers_2x2
    Dir.mktmpdir do |tmp|
      max_states = 1024
      valuer = NativeValuer.create(
        board_size: 2, max_exponent: 8, max_depth: 0, discount: DISCOUNT
      )
      layer_builder = LayerBuilder.new(2, tmp, max_states, valuer)
      layer_builder.build_start_state_layers

      # One layer part (json and vbyte) and two fragments (just vbyte)
      assert_equal 4, Dir.glob(File.join(tmp, '*')).size

      assert_equal 2, layer_builder.count_states(4, 1)
      layer_part_names = LayerPartName.glob(tmp)
      assert_equal 1, layer_part_names.size
      assert_equal 4, layer_part_names[0].sum
      assert_equal 1, layer_part_names[0].max_value
      states_4 = layer_part_names.first.read_states(2, folder: tmp)
      assert_states_equal [
        [0, 0,
         1, 1],
        [0, 1,
         1, 0]
      ], states_4

      layer_fragment_names = LayerFragmentName.glob(tmp).sort_by(&:output_sum)
      assert_equal 2, layer_fragment_names.size
      assert_equal 6, layer_fragment_names[0].output_sum
      assert_equal 8, layer_fragment_names[1].output_sum

      states_6 = layer_fragment_names[0].read_states(2, folder: tmp)
      states_8 = layer_fragment_names[1].read_states(2, folder: tmp)

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
    names = names.sort_by { |name| [name.sum, name.max_value] }
    assert_equal 3, names.count { |name| name.sum <= 6 }
    assert_equal 4, names[0].sum
    assert_equal 6, names[1].sum
    assert_equal 1, names[1].max_value
    assert_equal 6, names[2].sum
    assert_equal 2, names[2].max_value
    names
  end

  def check_layer_part_names_to_8(names)
    names = check_layer_part_names_to_6(names)
    assert_equal 6, names.count { |name| name.sum <= 8 }
    assert_equal 8, names[3].sum
    assert_equal 1, names[3].max_value
    assert_equal 8, names[4].sum
    assert_equal 2, names[4].max_value
    assert_equal 8, names[5].sum
    assert_equal 3, names[5].max_value
    names
  end

  def check_layer_part_names_to_8_nonempty(names)
    assert_equal 4, names.size
    names = names.sort_by { |name| [name.sum, name.max_value] }
    assert_equal [4, 6, 6, 8], names.map(&:sum)
    assert_equal [1, 1, 2, 2], names.map(&:max_value)
  end

  def test_build_layer
    Dir.mktmpdir do |tmp|
      max_states = 1024

      valuer = NativeValuer.create(
        board_size: 2, max_exponent: 8, max_depth: 0, discount: DISCOUNT
      )
      layer_builder = LayerBuilder.new(2, tmp, max_states, valuer)
      layer_builder.build_start_state_layers

      #
      # Build from layer 4.
      #
      assert_equal 2, layer_builder.build_layer(4)
      assert_equal 2, layer_builder.count_states(4, 1)

      assert_states_equal [
        [0, 1,
         1, 1]
      ], read_states_vbyte_2(layer_builder.layer_part_pathname(6, 1))
      assert_equal 1, layer_builder.count_states(6, 1)

      assert_states_equal [
        [0, 0,
         1, 2],
        [0, 1,
         2, 0]
      ], read_states_vbyte_2(layer_builder.layer_part_pathname(6, 2))
      assert_equal 2, layer_builder.count_states(6, 2)

      check_layer_part_names_to_6(LayerPartName.glob(tmp))
      check_layer_part_names_to_6(LayerPartInfoName.glob(tmp))

      #
      # Build from layer 6.
      #
      layer_builder.build_layer(6)

      check_layer_part_names_to_8(LayerPartName.glob(tmp))
      assert_states_equal [],
        read_states_vbyte_2(layer_builder.layer_part_pathname(8, 1))
      assert_equal 0, layer_builder.count_states(8, 1)
      assert_equal 4,
        read_states_vbyte_2(layer_builder.layer_part_pathname(8, 2)).size
      assert_equal 4, layer_builder.count_states(8, 2)
      assert_states_equal [],
        read_states_vbyte_2(layer_builder.layer_part_pathname(8, 3))
      assert_equal 0, layer_builder.count_states(8, 3)

      check_layer_part_names_to_8(LayerPartInfoName.glob(tmp))

      #
      # Test cleanup.
      #
      layer_builder.remove_empty_layer_parts(8)

      check_layer_part_names_to_8_nonempty(LayerPartName.glob(tmp))
      check_layer_part_names_to_8_nonempty(LayerPartInfoName.glob(tmp))
    end
  end

  def test_build_and_solve_2x2_to_128
    Dir.mktmpdir do |tmp|
      states_path = File.join(tmp, 'states')
      values_path = File.join(tmp, 'values')
      FileUtils.mkdir_p states_path
      FileUtils.mkdir_p values_path

      max_states = 1024
      valuer = NativeValuer.create(
        board_size: 2, max_exponent: 7, max_depth: 0, discount: DISCOUNT
      )
      layer_builder = LayerBuilder.new(2, states_path, max_states, valuer)
      layer_builder.build_start_state_layers
      layer_builder.build

      part_names = LayerPartName.glob(states_path)
      assert_equal 24, part_names.map(&:sum).uniq.size
      assert_equal(74, part_names.map do |part|
        part.read_states(2, folder: states_path).size
      end.inject(:+))

      layer_solver = LayerSolver.new(
        2,
        states_path,
        values_path,
        valuer
      )

      layer_solver.solve

      values_4_file = LayerPartValuesName.glob(values_path)
        .find { |name| name.sum == 4 && name.max_value == 1 }
      assert_equal 32, File.size(values_4_file.in(values_path))

      # This game is not winnable.
      state_values = values_4_file.read(2, folder: values_path)
      assert_equal 0, state_values[0][1]
      assert_equal 0, state_values[1][1]
    end
  end

  def test_build_and_solve_2x2_to_32
    Dir.mktmpdir do |tmp|
      states_path = File.join(tmp, 'states')
      values_path = File.join(tmp, 'values')
      FileUtils.mkdir_p states_path
      FileUtils.mkdir_p values_path

      max_states = 1024
      valuer = NativeValuer.create(
        board_size: 2, max_exponent: 5, max_depth: 0, discount: DISCOUNT
      )
      layer_builder = LayerBuilder.new(2, states_path, max_states, valuer)
      layer_builder.build_start_state_layers
      layer_builder.build

      part_names = LayerPartName.glob(states_path)
      assert_equal 18, part_names.map(&:sum).uniq.size
      assert_equal(57, part_names.map do |part|
        part.read_states(2, folder: states_path).size
      end.inject(:+))

      layer_solver = LayerSolver.new(
        2,
        states_path,
        values_path,
        valuer
      )

      layer_solver.solve

      values_4_file = LayerPartValuesName.glob(values_path)
        .find { |name| name.sum == 4 && name.max_value == 1 }
      assert_equal 32, File.size(values_4_file.in(values_path))

      # This game is quite hard to win.
      state_values = values_4_file.read(2, folder: values_path)
      assert_close 0.03831963657896261, state_values[0][1]
      assert_close 0.03831963657896261, state_values[1][1]
    end
  end
end
