# frozen_string_literal: true

module Twenty48
  #
  # Resolve a state by tracking a lower bound and upper bound on each cell
  # value.
  #
  # An empty cell initially has L = U = 0. A non-empty cell with value V
  # initially has L = U = V. Each time we move, we generate all of the possible
  # lines allowed by the bounds, find the new lines, and then adjust the bounds.
  # There are probably smarter ways of doing it without considering all possible
  # lines.
  #
  # One important note is that if a line includes a definite zero, we always
  # expand the bounds to include {0, 1, 2} as possibilities, since we may get a
  # 2^1 or 2^2 tile in any free space.
  #
  class BoundedResolver < Resolver
    def strategy_name
      :bounded
    end

    #
    # State with lower and upper bounds on the value in each cell.
    #
    class BoundedState
      def initialize(lower, upper)
        @lower = lower
        @upper = upper
      end

      attr_reader :lower
      attr_reader :upper

      def self.from_state(state)
        new(state.to_a, state.to_a)
      end

      def board_size
        Math.sqrt(@lower.size).to_i
      end

      def move(direction)
        # Note: if a move is impossible, this just assumes it's a no-op, and
        # then it continues the search. This is OK from a correctness point of
        # view, because we stop as soon as we find a definite win, but it does
        # lead to some wasted computation in cases where there are impossible
        # moves.
        case direction
        when :left
          update_each_row_with do |row_lower, row_upper|
            move_line(row_lower, row_upper)
          end
        when :right
          update_each_row_with do |row_lower, row_upper|
            move_line(row_lower.reverse, row_upper.reverse).map(&:reverse)
          end
        when :up
          update_each_col_with do |col_lower, col_upper|
            move_line(col_lower, col_upper)
          end
        when :down
          update_each_col_with do |col_lower, col_upper|
            move_line(col_lower.reverse, col_upper.reverse).map(&:reverse)
          end
        else
          raise "bad direction: #{direction}"
        end
      end

      def max_value
        @lower.zip(@upper).map do |lower_value, upper_value|
          upper_value if lower_value == upper_value
        end.compact.max || 0
      end

      def adjacent_pair?(value)
        any_row_or_col? do |lower, upper|
          adjacent_pair_in_line?(lower, upper, value)
        end
      end

      def inspect
        pairs = @lower.zip(@upper).map do |lower_value, upper_value|
          "#{lower_value}/#{upper_value}"
        end
        rows = pairs.each_slice(board_size).map { |row| row.join(' ') }
        "\n" + rows.join("\n")
      end

      private

      def move_line(line_lower, line_upper)
        n = line_lower.size
        new_lower = Array.new(n)
        new_upper = Array.new(n)
        make_possible_lines(line_lower, line_upper).each do |line|
          new_line = Line.move(line)
          n.times.each do |i|
            if new_lower[i].nil?
              new_lower[i] = new_line[i]
              new_upper[i] = new_line[i]
            else
              new_lower[i] = new_line[i] if new_line[i] < new_lower[i]
              new_upper[i] = new_line[i] if new_line[i] > new_upper[i]
            end
            new_upper[i] = 2 if new_lower[i] == 0 && new_upper[i] == 0
          end
        end
        [new_lower, new_upper]
      end

      def make_possible_lines(line_lower, line_upper)
        n = line_lower.size
        ranges = Array.new(n) { |i| (line_lower[i]..line_upper[i]).to_a }
        ranges.reduce(&:product).map(&:flatten)
      end

      def adjacent_pair_in_line?(lower, upper, value)
        found_first = false
        (0...lower.size).each do |i|
          if found_first
            next if upper[i] == 0
            return lower[i] == value && upper[i] == value
          end
          found_first = true if lower[i] == value && upper[i] == value
        end
        false
      end

      def any_row?
        n = board_size
        (0...n).any? { |i| yield(@lower[i * n, n], @upper[i * n, n]) }
      end

      def any_col?
        n = board_size
        (0...n).any? do |j|
          yield(
            (0...n).map { |i| @lower[i * n + j] },
            (0...n).map { |i| @upper[i * n + j] }
          )
        end
      end

      def any_row_or_col?(&block)
        any_row?(&block) || any_col?(&block)
      end

      def update_each_row_with
        n = board_size
        new_lower = @lower.dup
        new_upper = @upper.dup
        (0...n).each do |i|
          new_lower[i * n, n], new_upper[i * n, n] = yield(
            new_lower[i * n, n], new_upper[i * n, n])
        end
        self.class.new(new_lower, new_upper)
      end

      def update_each_col_with
        n = board_size
        new_lower = @lower.dup
        new_upper = @upper.dup
        (0...n).each do |j|
          col_lower = (0...n).map { |i| new_lower[i * n + j] }
          col_upper = (0...n).map { |i| new_upper[i * n + j] }
          new_col_lower, new_col_upper = yield(col_lower, col_upper)
          (0...n).each do |i|
            new_lower[i * n + j] = new_col_lower[i]
            new_upper[i * n + j] = new_col_upper[i]
          end
        end
        self.class.new(new_lower, new_upper)
      end
    end

    def moves_to_definite_win(state)
      # If there is no value close enough to the max exponent, we can skip this
      # check, because the maximum value can increase by at most one per move.
      delta = max_exponent - state.max_value
      return nil if delta > max_resolve_depth

      inner_moves_to_definite_win(
        BoundedState.from_state(state), max_resolve_depth
      )
    end

    private

    def inner_moves_to_definite_win(state, max_depth)
      delta = max_exponent - state.max_value
      return nil if delta > max_depth

      return 0 if delta == 0
      return 1 if delta == 1 && state.adjacent_pair?(max_exponent - 1)

      DIRECTIONS.map do |direction|
        successor = state.move(direction)
        moves = inner_moves_to_definite_win(successor, max_depth - 1)
        moves + 1 if moves
      end.compact.min
    end
  end
end
