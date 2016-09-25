# frozen_string_literal: true

require 'finite_mdp'

require_relative 'twenty_48/version'
require_relative 'twenty_48/builder'
require_relative 'twenty_48/graph'
require_relative 'twenty_48/line'
require_relative 'twenty_48/lru_cache'
require_relative 'twenty_48/non_cache'
require_relative 'twenty_48/resolver'
require_relative 'twenty_48/exact_resolver'
require_relative 'twenty_48/unknown_zeros_resolver'
require_relative 'twenty_48/state'
require_relative 'twenty_48/storage'

module Twenty48
  DIRECTIONS = [:left, :right, :up, :down].freeze

  RESOLVER_STRATEGIES = {
    exact: ExactResolver,
    unknown_zeros: UnknownZerosResolver
  }.freeze
end
