# frozen_string_literal: true

module Twenty48
  #
  # Utilities for deduplicating actions.
  #
  module ActionDeduplication
    module_function

    #
    # Check whether two successor hashes (from states to (probability, reward)
    # pairs) are equal within tolerance.
    #
    def successors_equal(successors0, successors1, tolerance = 1e-9)
      return false unless successors0.size == successors1.size
      states0 = successors0.keys.sort
      states1 = successors1.keys.sort
      return false unless states0 == states1
      states0.all? do |state|
        probability0, reward0 = successors0[state]
        probability1, reward1 = successors1[state]
        (probability0 - probability1).abs < tolerance &&
          (reward0 - reward1).abs < tolerance
      end
    end

    def deduplicate_actions(actions)
      actions.reject do |action0, successors0|
        actions.find do |action1, successors1|
          next if action0 >= action1
          successors_equal(successors0, successors1)
        end
      end
    end
  end
end
