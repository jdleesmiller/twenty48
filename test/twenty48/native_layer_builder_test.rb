# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerBuilderTest < Twenty48NativeTest
  include Twenty48

  def test_build_start_state_layers_2x2
    Dir.mktmpdir do |tmp|
      resolver = NativeResolver.create(2, 8)
      layer_builder = NativeLayerBuilder.create(2, tmp, resolver)
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
      resolver = NativeResolver.create(2, 8)
      layer_builder = NativeLayerBuilder.create(2, tmp, resolver)
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
end
