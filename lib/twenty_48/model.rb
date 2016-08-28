# frozen_string_literal: true

require 'set'

module Twenty48
  #
  # Would probably better be called a ModelBuilder or Generator.
  #
  class Model
    def initialize(board_size, max_exponent, max_end_state_moves = 0)
      raise 'board size too small' if board_size < 2
      raise 'max exponent too small' if max_exponent < 2

      @board_size = board_size
      @max_exponent = max_exponent
      @max_end_state_moves = max_end_state_moves

      @resolved_win_states = build_resolved_win_states
      @resolved_lose_state = build_resolved_lose_state
    end

    attr_reader :board_size
    attr_reader :max_exponent
    attr_reader :max_end_state_moves
    attr_reader :resolved_win_states
    attr_reader :resolved_lose_state

    #
    # We get two random tiles at the start.
    #
    def start_states
      length = @board_size**2
      empty_state_array = [0] * length
      states = Set.new
      (0...length).each do |i|
        (0...length).each do |j|
          next if i == j
          [1, 2].each do |value_i|
            [1, 2].each do |value_j|
              state_array = empty_state_array.dup
              state_array[i] = value_i
              state_array[j] = value_j
              states << resolve_state_array(state_array)
            end
          end
        end
      end
      states.sort
    end

    DIRECTIONS = [:left, :right, :up, :down].freeze

    RANDOM_TILES = { 1 => 0.9, 2 => 0.1 }.freeze

    # Generate the successors and include the probabilities. The probabilities
    # are normalized. Must not be called on a losing state or winning state.
    def random_tile_successors_hash(state)
      hash = Hash.new { 0 }

      cells_available = state.cells_available
      raise 'no cells available' if cells_available < 1
      raise 'all cells available' if cells_available >= @board_size**2

      state_array = state.to_a
      state_array.each.with_index do |value, i|
        next unless value.zero?
        RANDOM_TILES.each do |new_value, value_probability|
          new_state_array = state_array.dup
          new_state_array[i] = new_value
          new_state = resolve_state_array(new_state_array)
          hash[new_state] += value_probability / cells_available
        end
      end

      raise "non-normalized: #{state.inspect}" unless
        (hash.values.inject(:+) - 1).abs < 1e-6

      hash
    end

    #
    # Return a hash model (almost) -- it's missing the rewards; we will add
    # those later.
    #
    def build_hash_model
      model = {}
      stack = start_states

      tick = 0
      until stack.empty?
        tick += 1
        $stderr.puts [model.size, stack.size].inspect if (tick % 1000).zero?

        state = stack.pop
        next if model.key?(state)
        state_hash = model[state] = {}

        DIRECTIONS.each do |direction|
          new_state = state.move(direction)
          if new_state == state
            state_hash[direction] = { state => 1.0 }
          else
            successors_hash = random_tile_successors_hash(new_state)
            state_hash[direction] = successors_hash

            successors_hash.keys.each do |successor_state|
              stack.push successor_state unless model.key?(successor_state)
            end
          end
        end
      end

      model
    end

    #
    # Add in the rewards to the hash model (in place).
    #
    def add_rewards_to_hash(hash)
      hash.each do |_state0, state_hash|
        state_hash.each do |_action, action_hash|
          action_hash.each do |state1, probability|
            action_hash[state1] = [
              probability,
              state1.win?(max_exponent) ? 1 : 0
            ]
          end
        end
      end
    end

    def pretty_print_hash_model(model)
      model.keys.sort.map do |state0|
        actions = model[state0]
        [state0.to_s] +
          DIRECTIONS.map do |direction|
            successor_states = actions[direction]
            successor_states.keys.sort.map do |state1|
              probability = successor_states[state1]
              ["#{direction} -> #{probability}",
               state1.to_s].join("\n")
            end
          end + ['----------------------------------']
      end.flatten.join("\n")
    end

    def resolve_state_array(state_array)
      state = Twenty48::State.new(state_array)

      (0..max_end_state_moves).each do |move|
        return resolved_win_states[move] if win_in?(state, move)
        return resolved_lose_state if lose_in?(state, move)
      end

      state.canonicalize
    end

    def win_in?(state, moves)
      raise 'moves must be non-negative' if moves.negative?

      # We can skip this (fairly expensive) check if there is no value close
      # enough to the max exponent, because the maximum value can increase by
      # at most one per move.
      return false if state.max_value < max_exponent - moves

      case moves
      when 0
        state.win?(max_exponent)
      when 1
        # We can take a shortcut here by not enumerating the successor states,
        # because you only win on a move, not due to a random tile (for
        # max_exponent > 2).
        DIRECTIONS.any? do |direction|
          state.move(direction).win?(max_exponent)
        end
      else
        DIRECTIONS.map do |direction|
          move_state = state.move(direction)
          next if state == move_state

          move_state.random_successors.all? do |successor|
            win_in?(successor, moves - 1)
          end
        end.compact.any?
      end
    end

    def lose_in?(state, moves)
      raise 'moves must be non-negative' if moves.negative?

      # We can skip this (fairly expensive) calculation for states that have
      # too many available cells, because the number of filled cells can
      # increase by at most one per move.
      return false if state.cells_available > moves

      return state.lose? if moves.zero?

      DIRECTIONS.map do |direction|
        move_state = state.move(direction)
        next if state == move_state

        move_state.random_successors.all? do |successor|
          lose_in?(successor, moves - 1)
        end
      end.compact.all?
    end

    private

    def build_resolved_win_states
      result = []

      build_simple_resolved_win_states(result)

      if max_end_state_moves >= board_size
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
        board_size > 2 && max_end_state_moves >= max_exponent

      state_array = [0] * (board_size**2 - 1) + [max_exponent]
      max_moves = [max_end_state_moves, board_size - 1].min
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
      if max_end_state_moves > 1
        case max_exponent
        when 2 then result << State.new([0, 1, 1, 0])
        when 3 then result << State.new([0, 1, 2, 1])
        when 4 then result << State.new([0, 2, 3, 2])
        when 5 then result << State.new([1, 3, 4, 3])
        end
        # Otherwise, there are no win states.
      end
      if max_end_state_moves > 2
        case max_exponent
        when 3 then result << State.new([0, 1, 1, 2])
        when 4 then result << State.new([0, 2, 2, 3])
        when 5 then result << State.new([2, 2, 3, 4])
        end
      end
      if max_end_state_moves > 3
        case max_exponent
        when 3 then result << State.new([0, 0, 1, 2])
        when 4 then result << State.new([0, 1, 3, 2])
        end
        # There are no definite win states for max_exponent = 5, because until
        # you get 3 moves from the end, there's always a possibility of losing.
      end
      raise '5+ on the 2x2 board not done yet' if max_end_state_moves > 4
    end

    def build_resolved_lose_state
      State.new([0] * board_size**2)
    end
  end
end
