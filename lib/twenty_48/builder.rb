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
    def initialize(board_size, max_exponent, max_resolve_depth = 0)
      raise 'board size too small' if board_size < 2
      raise 'max exponent too small' if max_exponent < 2

      @board_size = board_size
      @max_exponent = max_exponent
      @max_resolve_depth = max_resolve_depth

      @resolved_win_states = build_resolved_win_states
      @resolved_lose_state = build_resolved_lose_state
      @resolve_cache = LruCache.new(max_size: 100_000)

      # We get almost no hits on the expand cache unless we are resolving
      # at least one state ahead.
      @expand_cache = if max_resolve_depth.positive?
                        LruCache.new(max_size: 100_000)
                      else
                        @expand_cache = NonCache.new
                      end

      @closed = SortedSet.new
      @open = []
    end

    attr_reader :board_size
    attr_reader :max_exponent
    attr_reader :max_resolve_depth
    attr_reader :resolved_win_states
    attr_reader :resolved_lose_state

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

    def build
      # Our usual transition model is not valid in the lose state, so we handle
      # it as a special case.
      @closed << resolved_lose_state
      yield resolved_lose_state, { down: { resolved_lose_state => [1, 0] } }

      start_states.each do |start_state|
        @open << resolve(start_state)
        while (state = @open.pop)
          next if @closed.member?(state)
          @closed << state
          yield state, close(state)
        end
      end
    end

    def moves_to_win(state, max_depth = max_resolve_depth)
      max_value = state.max_value
      return 0 if max_value >= max_exponent

      # If there is no value close enough to the max exponent, we can skip this
      # check, because the maximum value can increase by at most one per move.
      return nil if max_exponent - max_value > max_depth

      best = nil
      expand(state).each do |_action, successors|
        moves = same_result(successors) do |successor|
          moves_to_win(successor, max_depth - 1)
        end
        next if moves.nil?
        best = moves + 1 if best.nil? || best > moves + 1
        break if best == 1 # Not going to beat that.
      end
      best
    end

    #
    # Check whether we are certain to lose within the given number of moves.
    #
    def lose_within?(state, moves)
      raise 'negative moves' if moves.negative?

      return true if state.lose?

      # If the state has too many available cells, we can skip this check,
      # because the number of filled cells can increase by at most one per move.
      return false if moves.zero? || state.cells_available > moves

      expand(state).all? do |_action, successors|
        successors.all? do |successor, _|
          lose_within?(successor, moves - 1)
        end
      end
    end

    def win_in?(state, moves)
      raise 'moves must be non-negative' if moves.negative?

      # If there is no value close enough to the max exponent, we can skip this
      # check, because the maximum value can increase by at most one per move.
      max_value = state.max_value
      return false if max_value < max_exponent - moves
      return true if moves.zero?

      expand(state).any? do |_action, successors|
        successors.all? do |successor, _|
          win_in?(successor, moves - 1)
        end
      end
    end

    def lose_in?(state, moves)
      raise 'moves must be non-negative' if moves.negative?

      # If the state has too many available cells, we can skip this check,
      # because the number of filled cells can increase by at most one per move.
      return false if state.cells_available > moves
      return state.lose? if moves.zero?

      expand(state).all? do |_action, successors|
        successors.all? do |successor, _|
          lose_in?(successor, moves - 1)
        end
      end
    end

    #
    # The basic structure here is recursive:
    # - you win in n moves if there is some action such that you can win in n-1
    #   moves from all possible successors of that action
    # - you lose in n moves if for all possible actions, you lose in n-1 moves
    #   from all possible successors from each of those actions
    #
    # This implementation makes very heavy use of the `expand_cache`, since
    # it effectively has to expand all states from the current state several
    # times over.
    #
    def uncached_resolve(state)
      (0..max_resolve_depth).each do |move|
        return resolved_win_states[move] if win_in?(state, move)
        return resolved_lose_state if lose_in?(state, move)
      end
      state
    end

    #
    # Alternative recursion:
    # - if there is some action such that you win in exactly n-1 moves from
    #   all possible successor states of that action, then you win in n moves.
    # - if for all possible actions, you lose in n-1 moves from all possible
    #   successors from each of those actions, then you lose in n moves
    #
    def forward_resolve(state)
      win_in = approx_moves_to_win(state)
      return resolved_win_states[win_in] unless win_in.nil?
      return resolved_lose_state if lose_within?(state, max_resolve_depth)
      state
    end

    def resolve(state)
      cached_result = @resolve_cache[state]
      return cached_result if cached_result

      result = forward_resolve(state)
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

    #
    # Be pessimistic about all of the available cells. Assume they are filled
    # with blockers that can't be traversed or merged: large negative numbers.
    #
    def approx_moves_to_win(state, max_depth = max_resolve_depth)
      max_value = state.max_value
      return 0 if max_value >= max_exponent

      # If there is no value close enough to the max exponent, we can skip this
      # check, because the maximum value can increase by at most one per move.
      return nil if max_exponent - max_value > max_depth

      DIRECTIONS.map do |direction|
        move_state = state.move(direction)
        next if move_state == state

        state_array = move_state.to_a
        state_array.map!.with_index do |value, index|
          value.zero? ? -128 + index : value
        end
        new_state = State.new(state_array)

        moves = approx_moves_to_win(new_state, max_depth - 1)
        moves + 1 unless moves.nil?
      end.compact.min
    end

    private

    DIRECTIONS = [:left, :right, :up, :down].freeze

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

    def close(state)
      reward = state.win?(max_exponent) ? 1 : 0
      expand(state).map do |action, successors|
        new_successors = Hash.new { |hash, key| hash[key] = [0, reward] }
        successors.each do |successor, probability|
          resolved_successor = resolve(successor)
          @open << resolved_successor unless @closed.member?(resolved_successor)
          value = new_successors[resolved_successor]
          value[0] += probability
        end
        [action, new_successors]
      end.to_h
      # TODO: we could remove equivalent actions here --- check that the action
      # successor sets are identical (or equal within some numerical tolerance)
    end

    def build_resolved_win_states
      result = []

      build_simple_resolved_win_states(result)

      if max_resolve_depth >= board_size
        raise 'build_resolved_win_states not up to it' unless board_size == 2
        build_resolved_2x2_win_states(result)
      end

      result
    end

    #
    # It's easy if we can fit all of the tiles on one row. For example:
    # win:        [..., 0, 8]
    # win in one: [..., 0, 4, 4]
    # win in two: [..., 0, 2, 2, 4]
    #
    def build_simple_resolved_win_states(result)
      # If the exponent is not large enough, we'll get zeros.
      raise 'max end state moves too large' if
        board_size > 2 && max_resolve_depth >= max_exponent

      state_array = [0] * (board_size**2 - 1) + [max_exponent]
      max_moves = [max_resolve_depth, board_size - 1].min
      (0..max_moves).each do |move|
        result << State.new(state_array)
        top_index = state_array.length - 1 - move
        new_top = state_array[top_index] - 1
        state_array[top_index - 1] = new_top
        state_array[top_index] = new_top
      end
    end

    #
    # These don't follow any obvious pattern, so I have just hard coded them.
    # They are only really useful for testing, but we should have them for
    # completeness.
    #
    def build_resolved_2x2_win_states(result) # rubocop:disable Metrics/AbcSize
      if max_resolve_depth > 1
        case max_exponent
        when 2 then result << State.new([0, 1, 1, 0])
        when 3 then result << State.new([0, 1, 2, 1])
        when 4 then result << State.new([0, 2, 3, 2])
        when 5 then result << State.new([1, 3, 4, 3])
        end
        # Otherwise, there are no win states.
      end
      if max_resolve_depth > 2
        case max_exponent
        when 3 then result << State.new([0, 1, 1, 2])
        when 4 then result << State.new([0, 2, 2, 3])
        when 5 then result << State.new([2, 2, 3, 4])
        end
      end
      if max_resolve_depth > 3
        case max_exponent
        when 3 then result << State.new([0, 0, 1, 2])
        when 4 then result << State.new([0, 1, 3, 2])
        end
        # There are no definite win states for max_exponent = 5, because until
        # you get 3 moves from the end, there's always a possibility of losing.
      end
      raise '5+ on the 2x2 board not done yet' if max_resolve_depth > 4
    end

    def build_resolved_lose_state
      State.new([0] * board_size**2)
    end

    def same_result(successors, last_result = nil)
      successors.each do |successor, _|
        result = yield(successor)
        return nil if result.nil?
        if last_result.nil?
          last_result = result
        elsif last_result != result
          return nil
        end
      end
      last_result
    end
  end
end
