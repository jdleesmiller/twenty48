# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerBuilderTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  # def test_build_start_state_layers_2x2
  #   Dir.mktmpdir do |tmp|
  #     valuer = NativeValuer.create(
  #       board_size: 2, max_exponent: 8, max_depth: 0, discount: DISCOUNT
  #     )
  #     layer_builder = LayerBuilder.new(2, tmp, valuer)
  #     layer_builder.build_start_state_layers
  #
  #     assert_equal 3, Dir.glob(File.join(tmp, '*')).size
  #     assert_equal 16, File.stat(File.join(tmp, '0004.bin')).size
  #     assert_equal 34, File.stat(File.join(tmp, '0006.bin.xxd')).size
  #     assert_equal 34, File.stat(File.join(tmp, '0008.bin.xxd')).size
  #
  #     set = StateHashSet2.new(1024)
  #     set.load_binary(File.join(tmp, '0004.bin'))
  #     assert_states_equal [
  #       [0, 0,
  #        0, 0],
  #       [0, 0,
  #        1, 1],
  #       [0, 1,
  #        1, 0]
  #     ], set.to_a.sort
  #
  #     # The two unique states are:
  #     # 0 0  and  0 2
  #     # 2 4       4 0
  #     lines = File.readlines(File.join(tmp, '0006.bin.xxd')).sort.map(&:chomp)
  #     assert_equal %w(1200000000000000 2001000000000000), lines
  #   end
  # end
  #
  # def test_build_layer
  #   Dir.mktmpdir do |tmp|
  #     valuer = NativeValuer.create(
  #       board_size: 2, max_exponent: 8, max_depth: 0, discount: DISCOUNT
  #     )
  #     layer_builder = LayerBuilder.new(2, tmp, valuer)
  #     layer_builder.build_start_state_layers
  #
  #     batch_size = 2
  #     max_states = 1024
  #
  #     set = StateHashSet2.new(max_states)
  #     set.load_xxd(layer_builder.partial_layer_pathname(tmp, 6))
  #     original_6_states = set.to_a
  #
  #     layer_builder.build_layer(4, batch_size, max_states)
  #
  #     set = StateHashSet2.new(max_states)
  #     set.load_binary(File.join(tmp, '0006.bin'))
  #     new_6_states = set.to_a
  #
  #     assert_states_equal [
  #       [0, 1,
  #        1, 1]
  #     ], new_6_states - original_6_states
  #
  #     files = Dir.glob(File.join(tmp, '*'))
  #     files.map! { |pathname| File.basename(pathname) }
  #     assert_equal %w(0004.bin 0006.bin 0008.bin.xxd), files.sort
  #
  #     layer_builder.build_layer(6, batch_size, max_states)
  #
  #     files = Dir.glob(File.join(tmp, '*'))
  #     files.map! { |pathname| File.basename(pathname) }
  #     assert_equal %w(0004.bin 0006.bin 0008.bin 0010.bin.xxd), files.sort
  #   end
  # end

  def test_build_and_solve
    Dir.mktmpdir do |tmp|
      states_path = File.join(tmp, 'states')
      values_path = File.join(tmp, 'values')
      FileUtils.mkdir_p states_path
      FileUtils.mkdir_p values_path

      batch_size = 2
      max_states = 1024
      valuer = NativeValuer.create(
        board_size: 2, max_exponent: 7, max_depth: 0, discount: DISCOUNT
      )
      layer_builder = LayerBuilder.new(2, states_path, valuer)
      layer_builder.build_start_state_layers
      max_sum = layer_builder.build(batch_size, max_states)

      states_by_layer = layer_builder.states_by_layer(max_states)
      assert_equal 24, states_by_layer.size
      assert_equal 74, states_by_layer.values.flatten(1).count { |s| s.sum > 0 }

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
