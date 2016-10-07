# frozen_string_literal: true

require 'set'

module Twenty48
  #
  # Build a complete hash model for a 2048-like game.
  #
  # The general approach is to generate all possible start states and then
  # perform a depth-first search of the whole state space.
  #
  # The builder also 'resolves' states that are close to a win or a loss, in
  # order to avoid generating many states with unhelpful levels of detail ---
  # if you're going to win in 2 moves, you don't care how.
  #
  # To make this acceptably fast, we use two LRU caches to remember the results
  # of (1) expanding a state and (2) resolving a state.
  #
  class Builder
    include ActionDeduplication

    def initialize(board_size, max_exponent)
      raise 'board size too small' if board_size < 2
      raise 'max exponent too small' if max_exponent < 2

      @board_size = board_size
      @max_exponent = max_exponent

      @resolve_cache = LruCache.new(max_size: 300_000)
      @expand_cache = LruCache.new(max_size: 100_000)

      @closed = SortedSet.new
      @open = []
    end

    attr_reader :board_size
    attr_reader :max_exponent

    attr_reader :resolve_cache
    attr_reader :expand_cache

    #
    # Set of canonicalized, resolved states for which the transition function
    # is known (and has been yielded by `#build`)
    #
    attr_reader :closed

    #
    # Stack of canonicalized, resolved states that have been generated but not
    # yet closed.
    #
    attr_reader :open

    #
    # Generate all possible start states. We get two random tiles, each of
    # which can be either a 2 or a 4, at the start. The returned states are
    # canonicalized but not resolved.
    #
    def start_states
      empty_state = State.new([0] * @board_size**2)
      states = SortedSet.new
      empty_state.random_successors.each do |one_tile_state|
        one_tile_state.random_successors.each do |two_tile_state|
          states << two_tile_state.canonicalize
        end
      end
      states.to_a
    end

    def build(resolver, states = start_states)
      # Our usual transition model is not valid in the lose state, so we handle
      # it as a special case.
      @closed << resolver.lose_state
      yield resolver.lose_state, { down: { resolver.lose_state => [1, 0] } }

      states.each do |start_state|
        @open << resolve(resolver, start_state)
        while (state = @open.pop)
          next if @closed.member?(state)
          @closed << state
          yield state, close(resolver, state)
        end
      end
    end

    def expand(state)
      cached_result = @expand_cache[state]
      return cached_result if cached_result

      hash = {}
      DIRECTIONS.each do |direction|
        move_state = state.move(direction)
        next if move_state == state
        # TODO: we could easily check for a win here
        hash[direction] = move_state.random_successors_hash
      end
      # TODO: we could easily check for a loss here?
      @expand_cache[state] = hash
      hash
    end

    #
    # For resolvers that do not make good use of the expand cache (e.g. when
    # the max resolve depth is zero), there is no point in using it.
    #
    def disable_expand_cache
      @expand_cache = NonCache.new
    end

    private

    def resolve(resolver, state)
      cached_result = @resolve_cache[state]
      return cached_result if cached_result

      result = resolver.resolve(state)
      # result = uncached_resolve(state)
      # new_result = forward_resolve(state)

      # if result != new_result
      #   puts 'state'
      #   puts state.pretty_print
      #   puts 'old'
      #   puts result.pretty_print
      #   puts 'new'
      #   puts new_result.pretty_print
      #   raise 'resolve mismatch'
      # end

      @resolve_cache[state] = result
      result
    end

    def close(resolver, state)
      reward = state.win?(max_exponent) ? 1 : 0
      expand(state).map do |action, successors|
        new_successors = Hash.new { |hash, key| hash[key] = [0, reward] }
        successors.each do |successor, probability|
          resolved_successor = resolve(resolver, successor)
          @open << resolved_successor unless @closed.member?(resolved_successor)
          value = new_successors[resolved_successor]
          value[0] += probability
        end
        [action, new_successors]
      end.to_h
      # TODO: deduplicate_actions(hash)
      # TODO: we could also prune other actions when there is one that leads
      # uniquely to a resolved win state --- we resolve them because they're
      # the way to win. This seems pretty much the same as extending the
      # max depth by one, since it would then have resolved this state. It would
      # have to be the best resolved win state.
    end
  end
end
