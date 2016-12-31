# frozen_string_literal: true

require_relative 'helper'

class NativeStateValueMapTest < Twenty48NativeTest
  include Twenty48

  def test_state_value_map_2
    map = StateValueMap2.new

    assert_equal 0, map.size

    state_0 = make_state([0, 1, 2, 3])

    map.push_back(state_0, Twenty48::DIRECTION_LEFT, 0.123)
    assert_equal 1, map.size
    assert_equal 0.123, map.get_value(state_0)
    assert_equal Twenty48::DIRECTION_LEFT, map.get_action(state_0)

    state_1 = make_state([0, 1, 2, 4])

    map.push_back(state_1, Twenty48::DIRECTION_UP, 0.456)
    assert_equal 2, map.size
    assert_equal 0.456, map.get_value(state_1)
    assert_equal Twenty48::DIRECTION_UP, map.get_action(state_1)
  end
end
