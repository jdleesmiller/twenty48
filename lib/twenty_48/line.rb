# frozen_string_literal: true

module Twenty48
  #
  # Utilities for working with a single line (row or column) in a 2048 board.
  #
  module Line
    module_function

    #
    # Slide a row or column toward the start of the line.
    # Don't merge a tile that has already been merged.
    #
    def move(line)
      result = []
      last = nil
      line.each do |value|
        # Slide through empty spaces.
        next if value.zero?
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
  end
end
