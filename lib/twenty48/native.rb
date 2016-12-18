# frozen_string_literal: true

module Twenty48
  #
  # Common methods for the native board State classes.
  #
  module NativeState
    include CommonState

    def eql?(other)
      self == other
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
  # Common methods for the native Builder class.
  #
  module NativeBuilder
    def self.create(board_size, *args)
      case board_size
      when 2 then return Builder2.new(*args)
      when 3 then return Builder3.new(*args)
      when 4 then return Builder4.new(*args)
      end
      raise "bad builder board_size: #{board_size}"
    end
  end
end
