# frozen_string_literal: true

require_relative 'resolver_lose_shallow_tests'
require_relative 'resolver_lose_deep_tests'

module Twenty48
  module CommonResolverLoseTests
    include CommonResolverLoseShallowTests
    include CommonResolverLoseDeepTests
  end
end
