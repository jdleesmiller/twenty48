# frozen_string_literal: true

module Twenty48
  #
  # Accumulate probabilities for native state by sum and max value.
  #
  class LayerStateProbabilities
    def initialize
      @probabilities = Hash.new do |h0, sum|
        h0[sum] = Hash.new do |h1, max_value|
          h1[max_value] = Hash.new do |h2, state|
            h2[state] = 0.0
          end
        end
      end
    end

    def add(state, pr)
      @probabilities[state.sum][state.max_value][state.get_nybbles] += pr
    end

    def find(state)
      @probabilities[state.sum][state.max_value][state.get_nybbles]
    end

    def clear(sum, max_value)
      @probabilities[sum].delete(max_value)
    end

    def each_sum_max_value
      @probabilities.keys.sort.each do |sum|
        sum_prs = @probabilities[sum]
        sum_prs.keys.sort.each do |max_value|
          yield sum, max_value, sum_prs[max_value]
        end
      end
    end

    def flatten
      results = {}
      each_sum_max_value do |_sum, _max_value, states|
        results.merge!(states)
      end
      results
    end
  end
end
