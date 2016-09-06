# frozen_string_literal: true

module Twenty48
  #
  # Generate resolved, canonicalized win and lose states. There are not very
  # many, so some of them are just hand coded, but I think there are some
  # patterns we could exploit further.
  #
  class Resolver
    def initialize(board_size, max_exponent, max_resolve_depth)
      @board_size = board_size
      @max_exponent = max_exponent
      @max_resolve_depth = max_resolve_depth

      @win_states = build_wins
      @lose_state = build_lose

      raise 'cannot resolve far enough' if @win_states.size <= max_resolve_depth
    end

    attr_reader :board_size
    attr_reader :max_exponent
    attr_reader :max_resolve_depth

    attr_reader :win_states
    attr_reader :lose_state

    def win_state
      @win_states[0]
    end

    private

    def build_wins
      case @board_size
      when 2 then build_wins_2x2
      when 3 then build_wins_3x3
      when 4 then build_wins_4x4
      else
        raise 'board size not supported by Resolver'
      end
    end

    def build_wins_2x2
      # Note that there are only three definite win states for max_exponent = 5,
      # because until 3 moves from a win, loss is possible no matter the action.
      case @max_exponent
      when 2 then make_states(build_generic_wins(2))
      when 3 then make_states(build_generic_wins(3))
      else
        # The generic pattern is for e.g. 3 moves for max_exponent = 4 is
        # [1, 1, 2, 3], but the state below has lower ordinal state.
        make_states(build_generic_wins(2), [[
          0,                 @max_exponent - 2,
          @max_exponent - 2, @max_exponent - 1
        ]])
      end
    end

    def build_wins_3x3
      case @max_exponent
      when 2 then make_states(build_generic_wins(1), [[
        0, 0, 0,
        0, 0, 1,
        0, 1, 0
      ]])
      when 3 then make_states(build_generic_wins(3))
      when 4 then make_states(build_generic_wins(3))
      when 5 then make_states(build_generic_wins(4), [[
        0, 0, 1,
        0, 1, 0,
        4, 3, 2
      ]])
      when 6 then make_states(build_generic_wins(5), [[
        0, 1, 0,
        1, 0, 2,
        5, 4, 3
      ]])
      else
        make_states(build_generic_wins(@max_exponent - 1))
      end
    end

    def build_wins_4x4
      case @max_exponent
      when 2 then make_states(build_generic_wins(1), [[
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 1,
        0, 0, 1, 0
      ]])
      when 3 then make_states(build_generic_wins(2), [[
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 1,
        0, 2, 1, 0
      ]])
      when 4 then make_states(build_generic_wins(3), [[
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 1,
        3, 2, 1, 0
      ]])
      else
        make_states(build_generic_wins(@max_exponent))
      end
    end

    #
    # It's easy if we can fit all of the tiles on one row. For example:
    # win:        [..., 0, 8]
    # win in one: [..., 0, 4, 4]
    # win in two: [..., 0, 2, 2, 4]
    #
    def build_generic_wins(max_moves)
      max_moves = max_resolve_depth if max_moves > max_resolve_depth

      state_array = [0] * (board_size**2 - 1) + [max_exponent]
      result = [State.new(state_array)]

      top_index = state_array.length - 1
      sign = -1
      max_moves.times do |move|
        new_top = state_array[top_index] - 1

        if (move + 1) % board_size == 0
          sign *= -1
          new_top_index = top_index - board_size
        else
          new_top_index = top_index + sign
        end

        state_array[new_top_index] = [new_top, 1].max
        state_array[top_index] = new_top
        top_index = new_top_index
        result << State.new(state_array).canonicalize
      end

      result
    end

    def build_lose
      State.new([0] * board_size**2)
    end

    def make_states(states, state_arrays = [])
      all_states = states + state_arrays.map { |s| State.new(s) }
      all_states.take(max_resolve_depth + 1)
    end
  end
end
