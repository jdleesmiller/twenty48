# frozen_string_literal: true

require_relative 'helper'

class NativePolicyReaderWriterTest < Twenty48NativeTest
  include Twenty48

  def write_policy(pathname, policy)
    writer = PolicyWriter.new(pathname)
    policy.each do |direction|
      writer.write direction
    end
    writer.flush
    writer.close
  end

  def read_policy(pathname, count)
    reader = PolicyReader.new(pathname)
    Array.new(count) { reader.read }
  end

  def round_trip(pathname, policy)
    write_policy(pathname, policy)
    result = read_policy(pathname, policy.size)
    assert_equal result, policy
  end

  def test_read_write_policy
    Dir.mktmpdir do |tmp|
      file = File.join(tmp, 'test.policy')

      # Write no states.
      write_policy(file, [])
      assert_equal 0, File.size(file)

      reader = PolicyReader.new(file)
      assert_raises { reader.read }

      round_trip(file, [DIRECTION_UP])
      assert_equal 1, File.size(file)

      round_trip(file, [DIRECTION_UP, DIRECTION_DOWN])
      assert_equal 1, File.size(file)

      round_trip(file, [DIRECTION_DOWN, DIRECTION_UP, DIRECTION_LEFT])
      assert_equal 1, File.size(file)

      round_trip(file, [
        DIRECTION_DOWN, DIRECTION_UP, DIRECTION_LEFT, DIRECTION_RIGHT
      ])
      assert_equal 1, File.size(file)

      round_trip(file, [
        DIRECTION_DOWN, DIRECTION_UP, DIRECTION_LEFT, DIRECTION_RIGHT,
        DIRECTION_UP
      ])
      assert_equal 2, File.size(file)

      round_trip(file, [
        DIRECTION_DOWN, DIRECTION_UP, DIRECTION_LEFT, DIRECTION_RIGHT,
        DIRECTION_UP, DIRECTION_LEFT
      ])
      assert_equal 2, File.size(file)
    end
  end
end
