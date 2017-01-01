# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/resolver_lose_tests'

class ResolverLoseTest < Twenty48Test
  include Twenty48
  include CommonResolverLoseTests

  def make_resolver(board_size, max_exponent, depth)
    builder = Builder.new(board_size, max_exponent)
    Resolver.new(builder, depth)
  end

  def resolve_lose?(resolver, state_array)
    resolver.lose_within?(make_state(state_array), resolver.max_resolve_depth)
  end
end
