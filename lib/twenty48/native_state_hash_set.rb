# frozen_string_literal: true

require 'tmpdir'

module Twenty48
  #
  # Common methods for the native StateHashSet classes.
  #
  module NativeStateHashSet
    def self.create(board_size, max_states)
      klass = case board_size
              when 2 then StateHashSet2
              when 3 then StateHashSet3
              when 4 then StateHashSet4
              else raise "bad layer solver board_size: #{board_size}"
              end
      klass.new(max_states)
    end

    def empty?
      size == 1 # Don't count the lose state.
    end

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
