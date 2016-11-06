# frozen_string_literal: true

module Twenty48
  #
  # Methods shared between native and Ruby states.
  #
  module CommonState
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
  end
end
