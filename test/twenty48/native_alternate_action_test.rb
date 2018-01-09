# frozen_string_literal: true

require_relative 'helper'

class NativeAlternateActionTest < Twenty48NativeTest
  include Twenty48

  # Note: we store blocks of 16 states, so we need at least that number to test.
  TEST_DATA = [
    [DIRECTION_LEFT, 0.5, [0.5, 0.49, 0.2, 0.0]], # right
    [DIRECTION_UP, 0.8, [0.5, 0.49, 0.8, 0.0]], # no alt
    [DIRECTION_UP, 0.8, [0.5, 0.49, 0.8, 0.79]], # down
    [DIRECTION_UP, 0.8, [0.79, 0.49, 0.8, 0.79]], # down and left
    [DIRECTION_UP, 0.8, [0.79, 0.79, 0.8, 0.79]], # all
    [DIRECTION_DOWN, 0.9, [0.79, 0.79, 0.8, 0.9]], # no alt
    [DIRECTION_DOWN, 0.9, [0.89, 0.79, 0.8, 0.9]], # left
    [DIRECTION_DOWN, 0.9, [0.79, 0.89, 0.8, 0.9]], # right
    [DIRECTION_DOWN, 0.9, [0.79, 0.79, 0.89, 0.9]], # up
    [DIRECTION_RIGHT, 0.1, [0.0, 0.1, 0.0, 0.0]], # no alt
    [DIRECTION_RIGHT, 0.1, [0.09, 0.1, 0.0, 0.0]], # left
    [DIRECTION_RIGHT, 0.1, [0.09, 0.1, 0.09, 0.0]], # left, up
    [DIRECTION_RIGHT, 0.1, [0.09, 0.1, 0.09, 0.09]], # all
    [DIRECTION_LEFT, 0.1, [0.1, 0.0, 0.0, 0.0]], # no alt
    [DIRECTION_LEFT, 0.1, [0.1, 0.0, 0.0, 0.09]], # down
    [DIRECTION_LEFT, 0.1, [0.1, 0.0, 0.09, 0.09]], # up, down
    [DIRECTION_LEFT, 0.1, [0.1, 0.1, 0.09, 0.09]], # all
    [DIRECTION_LEFT, 0.1, [0.1, 0.1, 0.09, 0.09]], # repeat
    [DIRECTION_LEFT, 0.1, [0.1, 0.1, 0.09, 0.09]],
    [DIRECTION_LEFT, 0.1, [0.1, 0.1, 0.09, 0.09]],
    [DIRECTION_LEFT, 0.1, [0.1, 0.1, 0.09, 0.09]]
  ].freeze

  def make_alternate_actions(data, tolerance)
    data.map do |action, value, action_values|
      action_values.map do |action_value, index|
        next if action == index
        action_value > value - tolerance
      end
    end
  end

  def write_alternate_actions(
    alternate_actions_pathname, policy_pathname, data, tolerance
  )
    alternate_actions_writer = AlternateActionWriter.new(
      alternate_actions_pathname, tolerance
    )
    policy_writer = PolicyWriter.new(policy_pathname)
    data.each do |action, value, action_values|
      alternate_actions_writer.write action, value, *action_values
      policy_writer.write action
    end
    [alternate_actions_writer, policy_writer].each do |writer|
      writer.flush
      writer.close
    end
  end

  def round_trip(
    alternate_actions_pathname, policy_pathname, data, tolerance
  )
    write_alternate_actions(
      alternate_actions_pathname, policy_pathname, data, tolerance
    )
    policy_reader = PolicyReader.new(policy_pathname)
    result = AlternateActionReader.read(
      alternate_actions_pathname, policy_reader, data.size
    )
    assert_equal make_alternate_actions(data, tolerance), result
  end

  def test_read_write_policy
    Dir.mktmpdir do |tmp|
      alternate_actions_file = File.join(tmp, 'test.alternate')
      policy_file = File.join(tmp, 'test.policy')

      # Write no states.
      write_alternate_actions(alternate_actions_file, policy_file, [], 0.02)
      assert_equal 0, File.size(alternate_actions_file)
      assert_equal 0, File.size(policy_file)

      reader = AlternateActionReader.new(alternate_actions_file)
      assert_raises { reader.read(DIRECTION_LEFT) }

      (1..TEST_DATA.size).each do |n|
        round_trip(alternate_actions_file, policy_file, TEST_DATA[0, n], 0.02)
        assert_equal 6 * (n / 16.0).ceil, File.size(alternate_actions_file)
        assert_equal (n / 4.0).ceil, File.size(policy_file)
      end
    end
  end

  def test_policy_reader_skip
    Dir.mktmpdir do |tmp|
      alternate_actions_file = File.join(tmp, 'test.alternate')
      policy_file = File.join(tmp, 'test.policy')
      tolerance = 0.02

      write_alternate_actions(
        alternate_actions_file, policy_file, TEST_DATA, 0.02
      )

      n = TEST_DATA.size
      (0..n).each do |i|
        policy_reader = PolicyReader.new(policy_file)
        expected = make_alternate_actions(TEST_DATA[i...n], tolerance)
        assert_equal expected, AlternateActionReader.read(
          alternate_actions_file, policy_reader, n, skip: i
        )
      end
    end
  end
end
