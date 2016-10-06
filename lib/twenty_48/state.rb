# frozen_string_literal: true

module Twenty48
  #
  # A board state. This class is implemented to try to keep its memory footprint
  # small, because we're going to have many, many State instances.
  #
  # State objects are immutable.
  #
  # State objects implement content-based `eql?` and `hash`, because this is
  # required by {FiniteMDP::Model}.
  #
  class State
    def initialize(state_array)
      @data = pack(state_array)
    end

    attr_reader :data

    def board_size
      Math.sqrt(data.size).to_i
    end

    #
    # i = n * y + x
    # x = i % n
    # y = i / n
    #
    # x' = n - x - 1, y' = y =>
    #   i' = n*y + n - 1 - x = n*(y + 1) - (x + 1)
    #
    def reflect_horizontally
      transform { |n, x, y| n * (y + 1) - (x + 1) }
    end

    #
    # y' = n - y - 1, x' = x => i' = n*(n - y - 1) + x
    #
    def reflect_vertically
      transform { |n, x, y| n * (n - y - 1) + x }
    end

    #
    # x' = y, y' = x => i' = n*x + y
    #
    def transpose
      transform { |n, x, y| n * x + y }
    end

    def max_value
      to_a.max
    end

    def win?(max_exponent)
      to_a.any? { |value| value == max_exponent }
    end

    def lose?
      (0...board_size**2).none? { |index| can_move_tile?(index) }
    end

    def cells_available
      unpack(data).count(&:zero?)
    end

    #
    # Does the state contain a pair of cells, both with value `value`, separated
    # only by zero or more (known) zeros? If so, we can always swipe to get a
    # `value + 1` tile.
    #
    # @param [Boolean?] zeros_unknown treat zero as 'unknown', not 'empty'
    #
    def adjacent_pair?(value, zeros_unknown = false)
      any_row_or_col?(unpack(data)) do |line|
        Line.adjacent_pair?(line, value, zeros_unknown)
      end
    end

    def can_move_tile?(index)
      state = unpack(data)
      value = state[index]
      return false if value.zero?

      n = board_size
      x = index % n
      y = index.div(n)

      [
        [x.positive?, n * y + x - 1],   # left
        [x < n - 1,   n * y + x + 1],   # right
        [y.positive?, n * (y - 1) + x], # up
        [y < n - 1,   n * (y + 1) + x], # down
      ].any? do |interior, adjacent_index|
        next false unless interior
        other = state[adjacent_index]
        other == value || other.zero?
      end
    end

    #
    # Apply reflections and return the state with the lowest lexical index.
    #
    # There are eight reflections (including the identity) to be considered, as
    # expected from the order of the dihedral group $D_4$.
    #
    # ```
    # reflect hz:     L -> R, R -> L
    # reflect vt:     U -> D, D -> U
    # transpose:      L -> U, U -> L, R -> D, D -> R
    # anti-transpose: U -> R, R -> U, D -> L, L -> D
    # rotate 90:      L -> U, U -> R, R -> D, D -> L
    # rotate 270:     L -> D, D -> R, R -> U, U -> L
    # rotate 180:     U -> D, D -> U, L -> R, R -> L
    # ```
    #
    def canonicalize
      horizontal_reflection = reflect_horizontally
      vertical_reflection = reflect_vertically
      transposition = transpose
      rotated_90 = transposition.reflect_horizontally
      rotated_180 = horizontal_reflection.reflect_vertically
      rotated_270 = transposition.reflect_vertically
      anti_transposition = rotated_90.reflect_vertically # transpose rotated 180
      [self, horizontal_reflection, vertical_reflection,
       transposition, anti_transposition,
       rotated_90, rotated_180, rotated_270].min
    end

    #
    # Slide tiles left (-1, 0), right (+1, 0), up (0, -1) or down (0, +1).
    # Signs are for consistency with the 2048 source.
    #
    def move(direction, zeros_unknown = false)
      state = unpack(data)
      case direction
      when :left
        update_each_row_with(state) do |row|
          Line.move(row, zeros_unknown)
        end
      when :right
        update_each_row_with(state) do |row|
          Line.move(row.reverse, zeros_unknown).reverse
        end
      when :up
        update_each_col_with(state) do |col|
          Line.move(col, zeros_unknown)
        end
      when :down
        update_each_col_with(state) do |col|
          Line.move(col.reverse, zeros_unknown).reverse
        end
      else
        raise "bad direction: #{direction}"
      end
    end

    #
    # Generate a 2^1 with 90% probability and a 2^2 with 10% probability.
    #
    RANDOM_TILES = { 1 => 0.9, 2 => 0.1 }.freeze

    #
    # Generate all possible random successors without the probabilities.
    # We can add either a 2 or 4 tile (value 1 or 2) in any available cell.
    # The returned states are not canonicalized. If there are no available
    # cells, the state itself is returned as the only entry.
    #
    # TODO why not canonicalize?
    #
    def random_successors
      state_array = to_a
      new_states = []
      state_array.each.with_index do |value, i|
        next unless value.zero?
        RANDOM_TILES.each do |new_value, _|
          new_state_array = state_array.dup
          new_state_array[i] = new_value
          new_states << self.class.new(new_state_array)
        end
      end
      new_states << self if new_states.empty?
      new_states
    end

    #
    # Generate the successors and include the probabilities. The states are
    # canonicalized. The probabilities are normalized. If there are no
    # available cells, the state itself is returned as the only entry, with
    # probability 1.
    #
    def random_successors_hash
      state_array = to_a
      hash = Hash.new { 0 }
      cells_available = self.cells_available
      state_array.each.with_index do |value, i|
        next unless value.zero?
        RANDOM_TILES.each do |new_value, value_probability|
          new_state_array = state_array.dup
          new_state_array[i] = new_value
          new_state = self.class.new(new_state_array).canonicalize
          hash[new_state] += value_probability / cells_available
        end
      end
      hash[self] = 1.0 if hash.empty?
      check_normalised hash
      hash
    end

    def to_a
      unpack(data)
    end

    def to_s
      to_a.to_s
    end

    def inspect
      to_a.inspect
    end

    def pretty_print
      to_a.each_slice(board_size).map do |row|
        row.map do |entry|
          if entry.positive?
            format('%4d', 2**entry)
          else
            '   .'
          end
        end.join(' ')
      end.join("\n")
    end

    def ==(other)
      return false if other.nil?
      data.eql?(other.data)
    end

    alias eql? ==

    def hash
      data.hash
    end

    def <=>(other)
      data <=> other.data
    end

    private

    def transform
      n = board_size
      state = unpack(data)
      new_state = (0...state.length).map do |index|
        y, x = index.divmod(n)
        state[yield(n, x, y)]
      end
      self.class.new(new_state)
    end

    def any_row?(state)
      n = board_size
      (0...n).any? { |i| yield(state[i * n, n]) }
    end

    def any_col?(state)
      n = board_size
      (0...n).any? { |j| yield((0...n).map { |i| state[i * n + j] }) }
    end

    def any_row_or_col?(state, &block)
      any_row?(state, &block) || any_col?(state, &block)
    end

    def update_each_row_with(state)
      n = board_size
      (0...n).each do |i|
        state[i * n, n] = yield(state[i * n, n])
      end
      self.class.new(state)
    end

    def update_each_col_with(state)
      n = board_size
      (0...n).each do |j|
        col = (0...n).map do |i|
          state[i * n + j]
        end
        new_col = yield(col)
        (0...n).each do |i|
          state[i * n + j] = new_col[i]
        end
      end
      self.class.new(state)
    end

    def check_normalised(hash)
      raise "non-normalized: #{inspect}" unless
        (hash.values.inject(:+) - 1).abs < 1e-6
    end

    PACK_FORMAT = 'c*' # signed chars are enough

    def pack(state_array)
      state_array.pack(PACK_FORMAT)
    end

    def unpack(state_data)
      state_data.unpack(PACK_FORMAT)
    end
  end
end
