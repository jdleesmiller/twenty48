# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/resolver_lose_tests'

class NativeResolverLoseTest < Twenty48NativeTest
  include Twenty48
  include CommonResolverLoseTests

  def resolve_lose?(resolver, state_array)
    resolver.lose_within?(make_state(state_array), resolver.get_max_lose_depth)
  end
end
