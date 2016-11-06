# frozen_string_literal: true

require 'finite_mdp'

require_relative 'twenty48/version'
require_relative 'twenty48/action_deduplication'
require_relative 'twenty48/builder'
require_relative 'twenty48/graph'
require_relative 'twenty48/line'
require_relative 'twenty48/lru_cache'
require_relative 'twenty48/non_cache'
require_relative 'twenty48/resolver'
require_relative 'twenty48/exact_resolver'
require_relative 'twenty48/unknown_zeros_resolver'
require_relative 'twenty48/state'
require_relative 'twenty48/storage'

# Load native extension.
require_relative 'twenty48/twenty48'

module Twenty48
  DIRECTIONS = [:left, :right, :up, :down].freeze

  RESOLVER_STRATEGIES = {
    exact: ExactResolver,
    unknown_zeros: UnknownZerosResolver
  }.freeze
end
