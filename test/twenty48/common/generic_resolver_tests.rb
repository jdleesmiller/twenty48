# frozen_string_literal: true

require_relative 'generic_resolver_shallow_tests'
require_relative 'generic_resolver_deep_tests'

module Twenty48
  module CommonGenericResolverTests
    include CommonGenericResolverShallowTests
    include CommonGenericResolverDeepTests
  end
end
