# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/generic_resolver_tests'

class NativeResolverValueTest < Twenty48NativeTest
  include Twenty48
  include CommonGenericResolverTests

  DISCOUNT = 0.95

  def value_state(resolver, state_array)
    resolver.value(make_state(state_array), DISCOUNT)
  end

  def moves_to_win(native_resolver, state_array)
    # The generic tests are all in terms of number of moves to win, so for now
    # I have just called that as well to find the expected amount of
    # discounting, and then we check that.
    result = native_resolver.moves_to_win(make_state(state_array))
    value = value_state(native_resolver, state_array)
    if result == Resolver2::UNKNOWN_MOVES_TO_WIN
      assert_nan value
      return nil
    else
      assert_close DISCOUNT**result, value
      result
    end
  end
end
