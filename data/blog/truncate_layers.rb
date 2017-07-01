# frozen_string_literal: true

#
# If there are two consecutive layers with no states, we can't continue past
# that state, so we can truncate the counts there.
#

require 'csv'

data = CSV.read('layers.csv', headers: true)

grouped = data.group_by do |row|
  [row['board_size'], row['max_exponent']]
end

CSV.open('layers_truncated.csv', 'w') do |layer_csv|
  layer_csv << %w[board_size max_exponent layer_sum num_states]
  CSV.open('layers_truncated_total.csv', 'w') do |total_csv|
    total_csv << %w[board_size max_exponent total_states]
    grouped.each do |(board_size, max_exponent), rows|
      total = 0
      rows = rows.sort_by { |row| row['layer_sum'].to_i }
      max_index = (0...(rows.size - 1)).find do |i|
        rows[i]['num_states'].to_i == 0 && rows[i + 1]['num_states'].to_i == 0
      end || rows.size
      rows.take(max_index).each do |row|
        total += row['num_states'].to_i
        layer_csv << row
      end
      total_csv << [board_size.to_i, max_exponent.to_i, total + 1]
    end
  end
end
