# frozen_string_literal: true

require_relative 'helper'

class NativeValueLayerTest < Twenty48NativeTest
  include Twenty48

  def test_single_state_layer
    Dir.mktmpdir do |tmp|
      states_pathname = File.join(tmp, 'test.vbyte')
      values_pathname = File.join(tmp, 'test.values')

      state = NativeState.create([
        0, 0, 0,
        0, 0, 0,
        0, 0, 1
      ])

      vbyte_writer = VByteWriter.new(states_pathname)
      vbyte_writer.write(state.get_nybbles)
      vbyte_writer.close
      assert_equal vbyte_writer.get_bytes_written, File.size(states_pathname)

      File.open(values_pathname, 'wb') do |f|
        f.write([1.2].pack('D*'))
      end
      assert_equal 8, File.size(values_pathname)

      value_layer = ValueLayer.new(states_pathname, values_pathname)

      assert_equal 0, value_layer.lookup(state.get_nybbles)
      assert_equal 1.2, value_layer.get_value(state.get_nybbles)
    end
  end

  def test_multipage_layer
    Dir.mktmpdir do |tmp|
      states_pathname = File.join(tmp, 'test.vbyte')
      values_pathname = File.join(tmp, 'test.values')

      # Note: ordinarily, all of the states in a layer have the same sum; these
      # don't, but that does not pose any particular problem. Also, we ensure
      # that the states are not evenly spaced, so that if we are at the wrong
      # point in the byte stream, we'll detect it.
      num_states = 10_000
      nybbles = 1
      states = Array.new(num_states) do |i|
        nybbles += i
        NativeState.create_from_nybbles(4, nybbles)
      end

      vbyte_writer = VByteWriter.new(states_pathname)
      states.each do |state|
        vbyte_writer.write(state.get_nybbles)
      end
      vbyte_writer.close
      assert_equal vbyte_writer.get_bytes_written, File.size(states_pathname)

      File.open(values_pathname, 'wb') do |f|
        f.write((0...num_states).map { |i| i / 100.0 }.pack('D*'))
      end
      assert_equal num_states * 8, File.size(values_pathname)

      value_layer = ValueLayer.new(states_pathname, values_pathname)
      states.each.with_index do |state, index|
        # p [state, index]
        assert_equal index, value_layer.lookup(state.get_nybbles)
        assert_equal index / 100.0, value_layer.get_value(state.get_nybbles)
      end
    end
  end
end
