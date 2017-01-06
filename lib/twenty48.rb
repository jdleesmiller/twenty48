# frozen_string_literal: true

require 'finite_mdp'

require_relative 'twenty48/version'
require_relative 'twenty48/action_deduplication'
require_relative 'twenty48/builder'
require_relative 'twenty48/common/state'
require_relative 'twenty48/graph'
require_relative 'twenty48/line'
require_relative 'twenty48/lru_cache'
require_relative 'twenty48/non_cache'
require_relative 'twenty48/resolved_win_state_generator'
require_relative 'twenty48/resolver'
require_relative 'twenty48/bounded_resolver'
require_relative 'twenty48/exact_resolver'
require_relative 'twenty48/unknown_zeros_resolver'
require_relative 'twenty48/state'
require_relative 'twenty48/state_hash_set'
require_relative 'twenty48/storage'

# Load native extension.
require_relative 'twenty48/twenty48'
require_relative 'twenty48/native'
require_relative 'twenty48/native_layer_builder'
require_relative 'twenty48/native_state_hash_set'
require_relative 'twenty48/layer_builder'

module Twenty48
  DIRECTIONS = [:left, :right, :up, :down].freeze

  RESOLVER_STRATEGIES = {
    exact: ExactResolver,
    unknown_zeros: UnknownZerosResolver,
    bounded: BoundedResolver
  }.freeze
end
