# frozen_string_literal: true

module Twenty48
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
  class ExactResolver < Resolver
    def moves_to_definite_win(state)
      (0..max_resolve_depth).find { |move| move if win_in?(state, move) }
    end

    def win_in?(state, moves)
      raise 'moves must be non-negative' if moves.negative?

      # If there is no value close enough to the max exponent, we can skip this
      # check, because the maximum value can increase by at most one per move.
      max_value = state.max_value
      return false if max_value < max_exponent - moves
      return true if moves.zero?

      builder.expand(state).any? do |_action, successors|
        successors.all? { |successor, _| win_in?(successor, moves - 1) }
      end
    end
  end
end
