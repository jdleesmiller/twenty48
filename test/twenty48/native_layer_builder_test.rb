# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerBuilderTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  def test_build_start_state_layers_2x2
    Dir.mktmpdir do |tmp|
      valuer = NativeValuer.create(
        board_size: 2, max_exponent: 8, max_depth: 0, discount: DISCOUNT
      )
      layer_builder = NativeLayerBuilder.create(2, tmp, valuer)
      layer_builder.build_start_state_layers

      %w(0004.bin 0006.bin 0008.bin).each do |filename|
        stat = File.stat(File.join(tmp, filename))
        assert_equal 16, stat.size
      end

      set = StateHashSet2.new(1024)
      set.load_binary(File.join(tmp, '0004.bin'))
      assert_states_equal [
        [0, 0,
         0, 0],
        [0, 0,
         1, 1],
        [0, 1,
         1, 0]
      ], set.to_a.sort
    end
  end

  def test_build_layer
    Dir.mktmpdir do |tmp|
      valuer = NativeValuer.create(
        board_size: 2, max_exponent: 8, max_depth: 0, discount: DISCOUNT
      )
      layer_builder = NativeLayerBuilder.create(2, tmp, valuer)
      layer_builder.build_start_state_layers

      set = StateHashSet2.new(1024)
      set.load_binary(File.join(tmp, '0006.bin'))
      original_6_states = set.to_a

      layer_builder.build_layer(4, 1, 1024)

      set = StateHashSet2.new(1024)
      set.load_binary(File.join(tmp, '0006.bin'))
      new_6_states = set.to_a

      assert_states_equal [
        [0, 1,
         1, 1]
      ], new_6_states - original_6_states
    end
  end

  def test_build_and_solve
    Dir.mktmpdir do |tmp|
      states_path = File.join(tmp, 'states')
      values_path = File.join(tmp, 'values')
      FileUtils.mkdir_p states_path
      FileUtils.mkdir_p values_path

      max_states = 1024
      valuer = NativeValuer.create(
        board_size: 2, max_exponent: 7, max_depth: 0, discount: DISCOUNT
      )
      layer_builder = NativeLayerBuilder.create(2, states_path, valuer)
      max_sum = layer_builder.build(max_states)

      states_by_layer = layer_builder.states_by_layer(max_states)
      layer_builder.sort_all_layers
      sorted_states_by_layer = layer_builder.states_by_layer(max_states)

      assert_equal states_by_layer.keys, sorted_states_by_layer.keys
      states_by_layer.keys.each do |sum|
        assert_equal states_by_layer[sum], sorted_states_by_layer[sum]
      end

      layer_solver = NativeLayerSolver.create(
        2,
        states_path,
        values_path,
        max_sum,
        valuer
      )

      loop do
        layer_solver.solve
        break unless layer_solver.move_to_lower_layer
      end
    end
  end
end
