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

      assert_equal 6, Dir.glob(File.join(tmp, '*')).size
      states_4 = read_states_vbyte_2(File.join(tmp, '0004.vbyte'))
      states_6 = read_states_vbyte_2(File.join(tmp, '0006.vbyte'))
      states_8 = read_states_vbyte_2(File.join(tmp, '0008.vbyte'))

      assert_equal 2, states_4.size
      assert_equal 2, states_6.size
      assert_equal 2, states_8.size

      assert_equal 2, layer_builder.count_states(4)
      assert_equal 2, layer_builder.count_states(6)
      assert_equal 2, layer_builder.count_states(8)

      assert_states_equal [
        [0, 0,
         1, 1],
        [0, 1,
         1, 0]
      ], states_4

      # The two unique states are:
      # 0 0  and  0 2
      # 2 4       4 0
      assert_states_equal [
        [0, 0,
         1, 2],
        [0, 1,
         2, 0]
      ], states_6

      # Don't bother saving an index on start states.
      index_4 = layer_builder.read_layer_info(4)['index']
      assert_equal 1, index_4.size
      assert_equal 0, index_4[0].byte_offset
      assert_equal 0, index_4[0].previous
    end
  end

  def test_build_layer
    Dir.mktmpdir do |tmp|
      max_states = 1024

      valuer = NativeValuer.create(
        board_size: 2, max_exponent: 8, max_depth: 0, discount: DISCOUNT
      )
      layer_builder = LayerBuilder.new(2, tmp, max_states, valuer)
      layer_builder.build_start_state_layers

      pathname_6 = layer_builder.layer_pathname(6, folder: tmp)
      original_6_states = read_states_vbyte_2(pathname_6)

      layer_builder.build_layer(4)

      new_6_states = read_states_vbyte_2(pathname_6)

      assert_states_equal [
        [0, 1,
         1, 1]
      ], new_6_states - original_6_states

      files = Dir.glob(File.join(tmp, '*.vbyte'))
      files.map! { |pathname| File.basename(pathname) }
      assert_equal %w(0004.vbyte 0006.vbyte 0008.vbyte), files.sort

      files = Dir.glob(File.join(tmp, '*.json'))
      files.map! { |pathname| File.basename(pathname) }
      assert_equal %w(0004.json 0006.json 0008.json), files.sort

      layer_builder.build_layer(6)

      files = Dir.glob(File.join(tmp, '*.vbyte'))
      files.map! { |pathname| File.basename(pathname) }
      assert_equal %w(0004.vbyte 0006.vbyte 0008.vbyte 0010.vbyte), files.sort

      files = Dir.glob(File.join(tmp, '*.json'))
      files.map! { |pathname| File.basename(pathname) }
      assert_equal %w(0004.json 0006.json 0008.json 0010.json), files.sort
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

      states_by_layer = layer_builder.states_by_layer
      assert_equal 24, states_by_layer.size
      assert_equal 74, states_by_layer.values.flatten(1).count { |s| s.sum > 0 }

      layer_solver = LayerSolver.new(
        2,
        states_path,
        values_path,
        valuer
      )

      layer_solver.solve

      values_4_file = File.join(values_path, '0004.values')
      assert File.exist?(values_4_file)
      assert_equal 16, File.size(values_4_file)

      # This game is not winnable.
      assert_equal [0, 0], File.read(values_4_file).unpack('D*')
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

      states_by_layer = layer_builder.states_by_layer
      assert_equal 18, states_by_layer.size
      assert_equal 57, states_by_layer.values.flatten(1).count { |s| s.sum > 0 }

      layer_solver = LayerSolver.new(
        2,
        states_path,
        values_path,
        valuer
      )

      layer_solver.solve

      values_4_file = File.join(values_path, '0004.values')
      assert File.exist?(values_4_file)
      assert_equal 16, File.size(values_4_file)

      # This game is quite hard to win.
      values = File.read(values_4_file).unpack('D*')
      assert_close 0.03831963657896261, values[0]
      assert_close 0.03831963657896261, values[1]
    end
  end
end
