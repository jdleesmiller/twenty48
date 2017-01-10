# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/line_tests'

class NativeLineTest < Twenty48NativeTest
  include Twenty48

  # This is where the actual tests are defined; they call #move.
  include CommonLineWithKnownTests

  def make_line(array)
    case array.size
    when 2 then Line2.new(array)
    when 3 then Line3.new(array)
    when 4 then Line4.new(array)
    end
  end

  def move(line_array)
    make_line(line_array).move().to_a
  end

  def adjacent_pair?(line_array, value)
    make_line(line_array).has_adjacent_pair(value)
  end

  def test_to_i
    assert_equal 0x01, Line2.new([0, 1]).to_i
    assert_equal 0x10, Line2.new([1, 0]).to_i
    assert_equal 0x02, Line2.new([0, 2]).to_i
    assert_equal 0x20, Line2.new([2, 0]).to_i
  end
end
