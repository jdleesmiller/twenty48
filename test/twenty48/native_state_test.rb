# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/state_tests'

class NativeStateTest < Twenty48NativeTest
  include Twenty48

  # This is where the actual tests are defined.
  include CommonStateTests

  def test_state_sum
    assert_equal 2 + 4 + 8, make_state([0, 1, 2, 3]).sum
  end

  # TODO: migrate some tests
  #   state_t<2, 3> state_2_3;
  # std::cout << "is_lose: " << state_2_3.is_lose() << std::endl;
  # std::cout << "is_win: " << state_2_3.is_win() << std::endl;
  # std::cout << "max_value: " << (int)state_2_3.max_value() << std::endl;
  # std::cout << "available: " << state_2_3.cells_available() << std::endl;
  # state = Twenty48::Native::State2.new(0x0012)
  # p state.no_cells_available
  # p state.cells_available
  # p state.max_value
  # p state.any_at_least(1)
  # p state.any_at_least(2)
  # p state.to_a
  # p state.to_s
  # p state.get_row(0).to_s
  # p state.get_row(1).to_s
  # p state.get_col(0).to_s
  # p state.get_col(1).to_s
  #
  # p format('%x', state.set_row(state.to_i, 0, 0x34))
  # p format('%x', state.set_col(state.to_i, 0, 0x34))
  #
  # state = Twenty48::Native::State3.new(0x012_345_678)
  # p state.get_row(0).to_s
  # p state.get_row(1).to_s
  # p state.get_row(2).to_s
  # p state.get_col(0).to_s
  # p state.get_col(1).to_s
  # p state.get_col(2).to_s
end
