# frozen_string_literal: true

module Twenty48
  #
  # Resolve a state using a simple heuristic: treat zeros as 'unknowns'.
  #
  # This still uses expansion (like ExactResolver) to detect losing states.
  #
  class UnknownZerosResolver < Resolver
    def strategy_name
      :unknown_zeros
    end

    def moves_to_definite_win(state)
      inner_moves_to_definite_win(state, max_resolve_depth, false)
    end

    private

    def inner_moves_to_definite_win(state, max_depth, zeros_unknown)
      # If there is no value close enough to the max exponent, we can skip this
      # check, because the maximum value can increase by at most one per move.
      delta = max_exponent - state.max_value
      return nil if delta > max_depth

      return 0 if delta == 0
      return 1 if delta == 1 &&
          state.adjacent_pair?(max_exponent - 1, zeros_unknown)

      DIRECTIONS.map do |direction|
        successor = state.move(direction, zeros_unknown)
        moves = inner_moves_to_definite_win(successor, max_depth - 1, true)
        moves + 1 if moves
      end.compact.min
    end
  end
end
