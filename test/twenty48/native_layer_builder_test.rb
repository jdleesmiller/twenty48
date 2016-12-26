# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class NativeLayerBuilderTest < Twenty48NativeTest
  include Twenty48

  def test_build_start_state_layers_2x2
    Dir.mktmpdir do |tmp|
      layer_builder = LayerBuilder2.new(tmp)
      layer_builder.build_start_state_layers

      %w(0004.bin 0006.bin 0008.bin).each do |filename|
        stat = File.stat(File.join(tmp, filename))
        assert_equal 16, stat.size
      end

      data = File.binread(File.join(tmp, '0004.bin'))
      nybbles = data.unpack('Q*')
      assert_equal make_state([0, 0, 1, 1]), State2.new(nybbles[0])
      assert_equal make_state([0, 1, 1, 0]), State2.new(nybbles[1])
    end
  end
end
