# frozen_string_literal: true

require_relative 'line_with_known_tests'
require_relative 'line_with_unknown_tests'

module Twenty48
  module CommonLineTests
    include CommonLineWithKnownTests
    include CommonLineWithUnknownTests
  end
end
