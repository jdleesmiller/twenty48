# frozen_string_literal: true

require_relative 'helper'
require_relative 'common/line_tests'

class LineTest < Twenty48Test
  include Twenty48
  include Line
  include CommonLineTests
end
