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

  def round_trip(pathname, policy)
    write_policy(pathname, policy)
    result = PolicyReader.read(pathname, policy.size)
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

  def test_policy_reader_skip
    Dir.mktmpdir do |tmp|
      pathname = File.join(tmp, 'test.policy')

      policy = [
        DIRECTION_DOWN, DIRECTION_UP, DIRECTION_LEFT, DIRECTION_RIGHT,
        DIRECTION_UP, DIRECTION_DOWN
      ]

      write_policy(pathname, policy)
      n = policy.size
      (0..n).each do |i|
        assert_equal policy[i...n], PolicyReader.read(pathname, n, skip: i)
      end
    end
  end
end
