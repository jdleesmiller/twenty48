# frozen_string_literal: true

require 'csv'
require 'erb'

TOTALS = {
  basic: CSV.read('layers_basic_total.csv', headers: true),
  improved: CSV.read('layers_total.csv', headers: true),
  truncated: CSV.read('layers_truncated_total.csv', headers: true),
  reachable: CSV.read('reachable.csv', headers: true)
}.freeze

def number_with_comma(number)
  number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def lookup(estimate, board_size, max_exponent)
  result = TOTALS[estimate].find do |row|
    row['board_size'].to_i == board_size &&
      row['max_exponent'].to_i == max_exponent
  end
  if result
    number_with_comma(result['total_states'].to_i)
  else
    '?'
  end
end

BOARD_SIZES = 2..4
MAX_EXPONENTS = 3..11

puts ERB.new(DATA.read).result

__END__

<table>
  <thead>
    <tr>
      <th>Maximum Tile</th>
      <th>Method</th>
      <th colspan="3">Board Size</th>
    </tr>
    <tr>
      <th></th>
      <th></th>
      <th align="right">2x2</th>
      <th align="right">3x3</th>
      <th align="right">4x4</th>
    </tr>
  </thead>
  <tbody>
    <% MAX_EXPONENTS.each do |max_exponent| %>
    <tr>
      <th align="right" valign="top" rowspan="<%= TOTALS.size %>"><%= 2**max_exponent %></th>
      <td>Baseline</td>
      <% BOARD_SIZES.each do |board_size| %><td align="right"><%= lookup :basic, board_size, max_exponent %></td><% end %>
    </tr>
    <tr>
      <td>Improved</td>
      <% BOARD_SIZES.each do |board_size| %><td align="right"><%= lookup :improved, board_size, max_exponent %></td><% end %>
    </tr>
    <tr>
      <td>Truncated</td>
      <% BOARD_SIZES.each do |board_size| %><td align="right"><%= lookup :truncated, board_size, max_exponent %></td><% end %>
    </tr>
    <tr>
      <td>Reachable</td>
      <% BOARD_SIZES.each do |board_size| %><td align="right"><%= lookup :reachable, board_size, max_exponent %></td><% end %>
    </tr>
    <% end %>
  </tbody>
</table>
