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
      state.each_slice(@board_size).to_a
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

    def compare_states(state0, state1)
      fail 'state length mismatch' unless state0.length == state1.length
      (0...state0.length).each do |i|
        if state0[i] < state1[i]
          return -1
        elsif state0[i] > state1[i]
          return 1
        end
      end
      0
    end

    def state_less_than(state0, state1)
      compare_states(state0, state1) < 0
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
            '   .'
          end
        end.join(' ')
      end.join("\n")
    end

    #
    # We get two random tiles at the start.
    #
    def start_states
      length = @board_size ** 2
      empty_state = [0] * length
      states = Set.new
      (0...length).each do |i|
        (0...length).each do |j|
          next if i == j
          state = empty_state.dup
          state[i] = 1
          state[j] = 2
          states << canonicalize_state(state)
        end
      end
      states.sort { |state0, state1| compare_states(state0, state1) }
    end

    #
    # Slide a row or column toward the start of the line.
    # Don't merge a tile that has already been merged.
    #
    def move_line(line)
      result = []
      last = nil
      line.each do |value|
        # Slide through empty spaces.
        next if value == 0
        if last == value
          # Merge adjacent tiles.
          result[result.size - 1] += 1
          last = nil
        else
          # Keep the tile.
          result << value
          last = value
        end
      end
      result << 0 while result.size < line.size
      result
    end

    def update_each_row_with(state)
      n = @board_size
      state = state.dup
      (0...n).each do |i|
        state[i * n, n] = yield(state[i * n, n])
      end
      state
    end

    def update_each_col_with(state)
      n = @board_size
      state = state.dup
      (0...n).each do |j|
        col = (0...n).map do |i|
          state[i * n + j]
        end
        new_col = yield(col)
        (0...n).each do |i|
          state[i * n + j] = new_col[i]
        end
      end
      state
    end

    DIRECTIONS = [:left, :right, :up, :down]

    #
    # Slide tiles left (-1, 0), right (+1, 0), up (0, -1) or down (0, +1).
    # Signs are for consistency with the 2048 source.
    #
    def move(state, direction)
      case direction
      when :left
        update_each_row_with(state) do |row|
          move_line(row)
        end
      when :right
        update_each_row_with(state) do |row|
          move_line(row.reverse).reverse
        end
      when :up
        update_each_col_with(state) do |col|
          move_line(col)
        end
      when :down
        update_each_col_with(state) do |col|
          move_line(col.reverse).reverse
        end
      else
        fail "bad direction: #{direction}"
      end
    end

    def successors(state)
      results = Set.new
      DIRECTIONS.each do |direction|
        new_state = move(state, direction)
        if new_state != state
          results = results.union(random_tile_successors(new_state))
        else
          results << canonicalize_state(new_state)
        end
      end
      results.to_a
    end

    def random_tile_successors(state)
      results = Set.new
      state.each.with_index do |value, i|
        next unless value == 0
        [1, 2].each do |new_value|
          new_state = state.dup
          new_state[i] = new_value
          results << canonicalize_state(new_state)
        end
      end
      results
    end

    RANDOM_TILES = { 1 => 0.9, 2 => 0.1 }

    def reward_for_state(state)
      winning_state?(state) ? 1 : 0
    end

    # Generate the successors and include the probabilities. The probabilities
    # are normalized. Must not be called on a losing state or winning state.
    def random_tile_successors_hash(state)
      hash = Hash.new { 0 }

      num_available = state.count { |value| value == 0 }
      fail 'no cells available' if num_available < 1
      fail 'all cells available' if num_available >= state.size

      state.each.with_index do |value, i|
        next unless value == 0
        RANDOM_TILES.each do |new_value, value_probability|
          new_state = state.dup
          new_state[i] = new_value
          new_state = canonicalize_state(new_state)
          hash[new_state] += value_probability / num_available
        end
      end

      fail "non-normalized: #{state.inspect}" unless
        (hash.values.inject(:+) - 1).abs < 1e-6

      hash
    end

    def reachable_states
      results = Set.new
      queue = start_states

      tick = 0
      until queue.empty? do
        tick += 1
        p [results.size, queue.size] if tick % 1000 == 0
        state = queue.shift
        next if results.member?(state)
        results << state
        queue.push(*successors(state))
      end

      results.to_a.sort { |state0, state1| compare_states(state0, state1) }
    end

    def build_hash_model
      # Hash<state, Hash<action, Hash<state, [Float, Float]>>>
      model = {}
      stack = start_states

      tick = 0
      until stack.empty?
        tick += 1
        p [model.size, stack.size] if tick % 1000 == 0

        state = stack.pop
        next if model.key?(state)
        state_hash = model[state] = {}

        DIRECTIONS.each do |direction|
          new_state = move(state, direction)
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

    def pretty_print_hash_model(model)
      keys = model.keys.sort { |state0, state1| compare_states(state0, state1) }
      keys.map do |state0|
        actions = model[state0]
        [pretty_print_state(state0)] +
          actions.map do |action, successor_states|
            successor_states.map do |state1, probability|
              ["#{action} -> #{probability}",
               pretty_print_state(state1)].join("\n")
            end
          end + ['----------------------------------']
      end.flatten.join("\n")
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


