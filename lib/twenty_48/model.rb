# frozen_string_literal: true

require 'set'

module Twenty48
  #
  # Would probably better be called a ModelBuilder or Generator.
  #
  class Model
    def initialize(board_size, max_exponent, use_pre_winning_state = false)
      @board_size = board_size
      @max_exponent = max_exponent
      @use_pre_winning_state = use_pre_winning_state
    end

    attr_reader :board_size
    attr_reader :max_exponent
    attr_reader :use_pre_winning_state

    def pre_winning_state?(state)
      return false unless use_pre_winning_state
      DIRECTIONS.any? { |direction| state.move(direction).win?(max_exponent) }
    end

    def reduce_state(state_array)
      state = State.new(state_array)
      return winning_state if state.win?(max_exponent)
      return pre_winning_state if pre_winning_state?(state)
      return losing_state if state.lose?
      state.canonicalize
    end

    #
    # We get two random tiles at the start.
    #
    def start_states
      length = @board_size**2
      empty_state = [0] * length
      states = Set.new
      (0...length).each do |i|
        (0...length).each do |j|
          next if i == j
          [1, 2].each do |value_i|
            [1, 2].each do |value_j|
              state = empty_state.dup
              state[i] = value_i
              state[j] = value_j
              states << reduce_state(state)
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
          new_state = reduce_state(new_state_array)
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

    private

    def losing_state
      @losing_state ||= State.new([0] * @board_size**2)
    end

    def pre_winning_state
      @pre_winning_state ||= State.new(
        [0] * (@board_size**2 - 2) + [@max_exponent - 1, @max_exponent - 1]
      )
    end

    def winning_state
      @winning_sate ||= State.new([0] * (@board_size**2 - 1) + [@max_exponent])
    end
  end
end
