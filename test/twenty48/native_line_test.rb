# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/line_tests'

class NativeLineTest < Twenty48NativeTest
  include Twenty48

  # This is where the actual tests are defined; they call #move.
  include CommonLineTests

  def move(array)
    case array.size
    when 2 then Line2.new(array).move.to_a
    when 3 then Line3.new(array).move.to_a
    when 4 then Line4.new(array).move.to_a
    end
  end

  def adjacent_pair?(line_array, value, zeros_unknown = false)
    line = case line_array.size
           when 2 then Line2.new(line_array)
           when 3 then Line3.new(line_array)
           when 4 then Line4.new(line_array)
           end
    line.has_adjacent_pair(value, zeros_unknown)
  end

  def test_to_i
    assert_equal 0x01, Line2.new([0, 1]).to_i
    assert_equal 0x10, Line2.new([1, 0]).to_i
    assert_equal 0x02, Line2.new([0, 2]).to_i
    assert_equal 0x20, Line2.new([2, 0]).to_i
  end
end
