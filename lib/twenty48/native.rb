# frozen_string_literal: true

module Twenty48
  #
  # Common methods for the native board State classes.
  #
  module NativeState
    include CommonState

    def self.create(state_array)
      case state_array.size
      when 4 then Twenty48::State2.new(state_array)
      when 9 then Twenty48::State3.new(state_array)
      when 16 then Twenty48::State4.new(state_array)
      else
        raise "bad state array size: #{state_array.size}"
      end
    end

    def eql?(other)
      self == other
    end

    def hash
      get_nybbles.hash
    end

    def <=>(other)
      return 0 if self == other
      self < other ? -1 : 1
    end
  end

  #
  # 2x2 board state.
  #
  class State2
    include NativeState

    alias adjacent_pair? has_adjacent_pair

    def board_size
      2
    end
  end

  #
  # 3x3 board state.
  #
  class State3
    include NativeState

    alias adjacent_pair? has_adjacent_pair

    def board_size
      3
    end
  end

  #
  # 4x4 board state.
  #
  class State4
    include NativeState

    alias adjacent_pair? has_adjacent_pair

    def board_size
      4
    end
  end

  #
  # Common methods for the native Resolver class.
  #
  module NativeResolver
    def self.create(board_size, max_exponent,
      max_lose_depth: 0, max_win_depth: 0)
      win_states = ResolvedWinStateGenerator.new(
        board_size, max_exponent, max_win_depth
      ).build_wins.map { |state| NativeState.create(state.to_a) }
      klass = case board_size
              when 2 then Resolver2
              when 3 then Resolver3
              when 4 then Resolver4
              else raise "bad resolver board_size: #{board_size}"
              end
      klass.new(max_exponent, max_lose_depth, win_states)
    end
  end

  #
  # Native state resolver for 2x2 boards.
  #
  class Resolver2
    alias lose_within? lose_within
  end

  #
  # Native state resolver for 3x3 boards.
  #
  class Resolver3
    alias lose_within? lose_within
  end

  #
  # Native state resolver for 4x4 boards.
  #
  class Resolver4
    alias lose_within? lose_within
  end

  #
  # Common methods for the native Builder class.
  #
  module NativeBuilder
    def self.create(board_size, resolver, max_states: 2**20)
      klass = case board_size
              when 2 then Builder2
              when 3 then Builder3
              when 4 then Builder4
              else raise "bad builder board_size: #{board_size}"
              end
      klass.new(resolver, max_states)
    end
  end

  #
  # Common methods for the native LayerBuilder class.
  #
  module NativeLayerBuilder
    def self.create(board_size, data_path, resolver)
      klass = case board_size
              when 2 then LayerBuilder2
              when 3 then LayerBuilder3
              when 4 then LayerBuilder4
              else raise "bad layer builder board_size: #{board_size}"
              end
      klass.new(data_path, resolver)
    end
  end

  #
  # Common methods for the native LayerSolver class.
  #
  module NativeLayerSolver
    def self.create(board_size, *args)
      klass = case board_size
              when 2 then LayerSolver2
              when 3 then LayerSolver3
              when 4 then LayerSolver4
              else raise "bad layer solver board_size: #{board_size}"
              end
      klass.new(*args)
    end
  end

  #
  # Common methods for the native StateHashSet classes.
  #
  module NativeStateHashSet
    def <<(state)
      insert state
    end

    def fill_factor
      size.to_f / max_size
    end
  end

  #
  # Hash set for 2x2 states.
  #
  class StateHashSet2
    include NativeStateHashSet

    alias member? member
  end

  #
  # Hash set for 3x3 states.
  #
  class StateHashSet3
    include NativeStateHashSet

    alias member? member
  end

  #
  # Hash set for 4x4 states.
  #
  class StateHashSet4
    include NativeStateHashSet

    alias member? member
  end
end
