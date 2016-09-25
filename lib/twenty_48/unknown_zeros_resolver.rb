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
      inner_moves_to_definite_win(state, max_resolve_depth)
    end

    private

    def inner_moves_to_definite_win(state, max_depth)
      max_value = state.max_value
      return 0 if max_value >= max_exponent

      # If there is no value close enough to the max exponent, we can skip this
      # check, because the maximum value can increase by at most one per move.
      return nil if max_exponent - max_value > max_depth

      DIRECTIONS.map do |direction|
        zeros_unknown = max_depth < max_resolve_depth
        successor = state.move(direction, zeros_unknown)
        moves = inner_moves_to_definite_win(successor, max_depth - 1)
        moves + 1 if moves
      end.compact.min
    end
  end
end
