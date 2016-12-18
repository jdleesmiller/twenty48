# frozen_string_literal: true

module Twenty48
  #
  # Generate resolved, canonicalized win and lose states. There are not very
  # many, so some of them are just hand coded, but I think there are some
  # patterns we could exploit further.
  #
  # Also, provide a `resolve` method to resolve states into these resolved
  # win and lose states.
  #
  class Resolver
    def initialize(builder, max_resolve_depth)
      @builder = builder
      @max_resolve_depth = max_resolve_depth

      @win_states = build_wins
      @lose_state = build_lose

      builder.disable_expand_cache if max_resolve_depth == 0

      raise 'cannot resolve far enough' if @win_states.size <= max_resolve_depth
    end

    def self.new_from_strategy_name(strategy_name, builder, max_resolve_depth)
      klass = RESOLVER_STRATEGIES[strategy_name.to_sym]
      klass&.new(builder, max_resolve_depth)
    end

    def board_size
      @builder.board_size
    end

    def max_exponent
      @builder.max_exponent
    end

    attr_reader :builder
    attr_reader :max_resolve_depth

    attr_reader :win_states
    attr_reader :lose_state

    #
    # The resolved win state.
    #
    def win_state
      @win_states[0]
    end

    #
    # If the given state can be resolved into a known win or lose state by
    # searching ahead, return the resolved state. Otherwise, just return the
    # given state.
    #
    # @param [State] state
    # @return [State] a resolved state, or just `state`
    #
    def resolve(state)
      win_in = moves_to_definite_win(state)
      return win_states[win_in] unless win_in.nil?
      return lose_state if lose_within?(state, max_resolve_depth)
      state
    end

    #
    # Subclasses implement this to provide different win state resolution
    # strateges.
    #
    # @abstract
    # @param [State] state
    # @return [Integer?] number of moves until win, if known
    #
    def moves_to_definite_win(_state)
      raise NotImplementedError
    end

    #
    # @param [State] state
    # @param [Integer] moves non-negative
    #
    def lose_within?(state, moves)
      raise 'negative moves' if moves.negative?

      return true if state.lose?

      # If the state has too many available cells, we can skip this check,
      # because the number of filled cells can increase by at most one per move.
      return false if moves.zero? || state.cells_available > moves

      builder.expand(state).all? do |_action, successors|
        successors.all? { |successor, _| lose_within?(successor, moves - 1) }
      end
    end

    private

    def build_wins
      ResolvedWinStateGenerator.new(
        board_size, max_exponent, max_resolve_depth
      ).build_wins
    end

    def build_lose
      State.new([0] * board_size**2)
    end
  end
end
