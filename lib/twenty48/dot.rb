# frozen_string_literal: true

module Twenty48
  #
  # Utilities for drawing 2048 boards with dot.
  #
  module Dot
    module_function

    def node_name(state)
      "s#{state.to_a.join('_')}"
    end

    def node_cell_labels(state, board_digits)
      state.to_a.map do |cell_value|
        string_value = if cell_value.positive?
                         format("%#{board_digits}d", 2**cell_value)
                       else
                         ' ' * board_digits
                       end
        string_value.gsub(' ', '&nbsp;')
      end
    end

    def node_label(state, board_digits)
      label_values = node_cell_labels(state, board_digits)

      label_values.each_slice(state.board_size)
        .map { |values| values.join('|') }
        .join('}|{')
    end
  end
end
