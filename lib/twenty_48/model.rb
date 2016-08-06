require 'finite_mdp'
require 'set'

module Twenty48
  class Model
    include FiniteMDP::Model

    def initialize(board_size, max_exponent)
      @board_size = board_size
      @max_exponent = max_exponent
    end

    attr_reader :board_size
    attr_reader :max_exponent

    def unflatten_state(state)
      rows = []
      state.each_slice(@board_size) do |row|
        rows << row
      end
      rows
    end

    #
    # i = n * y + x
    # x = i % n
    # y = i / n
    #
    # x' = n - x - 1, y' = y =>
    #   i' = n*y + n - 1 - x = n*(y + 1) - (x + 1)
    #
    def reflect_state_horizontally(state)
      n = @board_size
      (0...state.length).map do |index|
        state[n * (index.div(n) + 1) - (index % n + 1)]
      end
    end

    #
    # y' = n - y - 1, x' = x =>
    #   i' = n*(n - y - 1) + x
    #
    def reflect_state_vertically(state)
      n = @board_size
      (0...state.length).map do |index|
        state[n * (n - index.div(n) - 1) + index % n]
      end
    end

    #
    # x' = y, y' = x =>
    #   i' = n*x + y
    #
    def reflect_state_diagonally(state)
      n = @board_size
      (0...state.length).map do |index|
        state[n * (index % n) + index.div(n)]
      end
    end

    def winning_state?(state)
      state.any? { |value| value == @max_exponent }
    end

    def can_move_tile?(state, index)
      value = state[index]
      return false if value == 0

      n = @board_size
      x = index % n
      y = index.div(n)

      if x > 0 # left
        other = state[n * y + x - 1]
        return true if other == value || other == 0
      end
      if x < n - 1 # right
        other = state[n * y + x + 1]
        return true if other == value || other == 0
      end
      if y > 0 # up
        other = state[n * (y - 1) + x]
        return true if other == value || other == 0
      end
      if y < n - 1 # down
        other = state[n * (y + 1) + x]
        return true if other == value || other == 0
      end
      false
    end

    def losing_state?(state)
      (0...state.length).none? do |index|
        can_move_tile?(state, index)
      end
    end

    #
    # Need to try all equivalent states obtained by reflection.
    #
    def canonicalize_state(state)
      return winning_state if winning_state?(state)
      return losing_state if losing_state?(state)

      best_state = state

      hz = reflect_state_horizontally(state)
      best_state = hz if state_less_than(hz, best_state)

      vt = reflect_state_vertically(state)
      best_state = vt if state_less_than(vt, best_state)

      hz_vt = reflect_state_vertically(hz)
      best_state = hz_vt if state_less_than(hz_vt, best_state)

      diag = reflect_state_diagonally(state)
      best_state = diag if state_less_than(diag, best_state)

      diag_hz = reflect_state_horizontally(diag)
      best_state = diag_hz if state_less_than(diag_hz, best_state)

      diag_vt = reflect_state_vertically(diag)
      best_state = diag_vt if state_less_than(diag_vt, best_state)

      diag_hz_vt = reflect_state_vertically(diag_hz)
      best_state = diag_hz_vt if state_less_than(diag_hz_vt, best_state)

      best_state
    end

    def state_less_than(state0, state1)
      fail 'state length mismatch' unless state0.length == state1.length
      (0...state0.length).each do |i|
        if state0[i] < state1[i]
          return true
        elsif state0[i] > state1[i]
          return false
        end
      end
      false
    end

    def states
      states = Set[]
      each_candidate_state do |state|
        states << canonicalize_state(state)
      end
      states.to_a
    end

    def pretty_print_state(state)
      unflatten_state(state).map do |row|
        row.map do |entry|
          if entry > 0
            format('%4d', 2 ** entry)
          else
            '    '
          end
        end.join(' ')
      end.join("\n")
    end

    private

    def losing_state
      @losing_state ||= [0] * @board_size ** 2
    end

    def winning_state
      @winning_sate ||= [0] * (@board_size ** 2 - 1) + [@max_exponent]
    end

    def each_candidate_state
      length = @board_size ** 2
      state = [0] * length
      loop do
        index = length - 1
        state[index] += 1
        while index >= 0 && state[index] > @max_exponent
          state[index] = 0
          index -= 1
          state[index] += 1
        end
        break if index < 0
        yield state.dup
      end
    end
  end
end


