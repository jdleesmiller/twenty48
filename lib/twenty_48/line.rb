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
    # @param [Boolean?] zeros_unknown treat zero as 'unknown', not 'empty'
    #
    def move(line, zeros_unknown = false)
      result = Array.new(line.size, 0)
      i = 0
      last = nil
      line.each do |value|
        # Slide through empty spaces, unless zeros are unknowns, in which case
        # all subsequent tiles are unknown.
        if value.zero?
          break if zeros_unknown
          next
        end
        if last == value
          # Merge adjacent tiles.
          result[i - 1] += 1
          last = nil
        else
          # Keep the tile.
          result[i] = value
          i += 1
          last = value
        end
      end
      result
    end

    #
    # Does the line contain a pair of cells, both with value `value`, separated
    # only by zero or more (known) zeros? If so, we can always swipe along the
    # line to get the `value + 1` tile.
    #
    # @param [Boolean?] zeros_unknown treat zero as 'unknown', not 'empty'
    #
    def adjacent_pair?(line, value, zeros_unknown = false)
      found_first = false
      line.each do |cell_value|
        if found_first
          next if !zeros_unknown && cell_value == 0
          return cell_value == value
        end
        found_first = true if cell_value == value
      end
      false
    end

    # This function was identified as a hot spot in profiling. I thought this
    # in-place version might be faster, but it does not seem to be true. Keeping
    # it around in case we want to try it again some time.
    # def move(line)
    #   n = line.size
    #   i = -1
    #   done = 0
    #   merged = 0
    #   while (i += 1) < n
    #     next if (value = line[i]).zero?
    #     if done > merged && line[done - 1] == value
    #       line[done - 1] += 1
    #       line[i] = 0
    #       merged = done
    #     else
    #       if i > done
    #         line[done] = value
    #         line[i] = 0
    #       end
    #       done += 1
    #     end
    #   end
    #   line
    # end
  end
end
