# frozen_string_literal: true

require 'tsort'

module Twenty48
  #
  # Helper functions for building and calculating properties of absorbing
  # Markov chains. These aren't loaded by default, because they're only used in
  # a few utilities.
  #
  module MarkovChainUtilities
    module_function

    def setup_topological_sort(transitions)
      class <<transitions
        include TSort
        alias_method :tsort_each_node, :each_key
        def tsort_each_child(node0)
          fetch(node0, {}).each_key do |node1|
            yield node1
          end
        end
      end
    end

    #
    # Order states by sum, then lexically.
    #
    def sort_states(states)
      states.sort_by do |state|
        [state.sum, state]
      end
    end

    def find_state_index(states, state)
      key = [state.sum, state]
      states.bsearch_index { |x| key <=> [x.sum, x] }
    end

    #
    # P[:s][:t] is the probability of transitioning from state s to state t.
    #
    def make_transition_hash
      Hash.new do |h0, state0|
        h0[state0] = Hash.new do |h1, state1|
          h1[state1] = 0.0
        end
      end
    end

    def find_hitting_times_directly(transitions)
      setup_topological_sort transitions
      successor_states = transitions.tsort

      win_states = find_absorbing_states(transitions)
      other_states = successor_states - win_states

      hitting_times = {}
      win_states.each do |win_state|
        hitting_times[win_state] = 0
      end
      other_states.each do |state|
        hitting_times[state] = 1.0
        transitions[state].each do |state1, pr|
          hitting_times[state] += pr * hitting_times[state1]
        end
      end

      hitting_times
    end

    def find_transient_probabilities_directly(transitions)
      setup_topological_sort transitions
      states = transitions.tsort

      transient_states = states - find_absorbing_states(transitions)
      transient_states.reverse!

      transient_probabilities = Hash.new { 0.0 }
      prestart_state = transient_states.first
      transient_probabilities[prestart_state] = 1.0

      transient_states.each do |state0|
        transitions[state0].each do |state1, pr|
          transient_probabilities[state1] +=
            transient_probabilities[state0] * pr
        end
      end

      transient_probabilities
    end

    def find_absorbing_states(transitions)
      result = Set.new
      transitions.each_value do |successors|
        successors.each_key do |state1|
          result << state1 unless transitions.key?(state1)
        end
      end
      result.to_a
    end

    def make_transition_matrix(transitions, row_states, col_states)
      matrix = NMatrix.float(col_states.size, row_states.size)
      transitions.each do |state0, successors|
        i = find_state_index(row_states, state0)
        next unless i
        successors.each do |state1, pr|
          j = find_state_index(col_states, state1)
          next unless j
          matrix[j, i] = pr
        end
      end
      matrix
    end

    def make_fundamental_matrices_for_transitions(transitions)
      transient_states = sort_states(transitions.keys)
      transient_n = transient_states.size
      transient_q = make_transition_matrix(
        transitions, transient_states, transient_states
      )

      absorbing_states = sort_states(find_absorbing_states(transitions))
      absorbing_n = absorbing_states.size
      absorbing_r = make_transition_matrix(
        transitions, transient_states, absorbing_states
      )

      identity = NMatrix.float(absorbing_n, absorbing_n).diagonal!(1)

      n = transient_n + absorbing_n
      fundamental = NMatrix.float(n, n)
      fundamental[0...transient_n, 0...transient_n] = transient_q
      fundamental[transient_n...n, 0...transient_n] = absorbing_r
      fundamental[transient_n...n, transient_n...n] = identity

      [
        transient_states, absorbing_states,
        transient_q, absorbing_r, identity,
        fundamental
      ]
    end

    def find_expected_steps_from_q(transient_states, transient_q)
      transient_n = transient_states.size
      identity = NMatrix.float(transient_n, transient_n).diagonal!(1)
      ones = NVector.float(transient_n).fill!(1)

      # Expectation: t = N1 for N = (I - Q)^{-1}
      t = ones / (identity - transient_q)

      # Variance: (2N - I)t - t_sq
      # If (I-Q)v = 2t, then the variance is v - It - t_sq
      v = (2 * t) / (identity - transient_q)
      t_sq = NVector[NArray[t] * NArray[t]][nil, 0, 0]
      vt = v - t - t_sq

      [transient_states, t, vt]
    end

    def find_transient_probabilities_from_q(transient_states, transient_q)
      # Can't see any way of avoiding the explicit matrix inverse on this one,
      # because we need the diagonal.
      # H = (N - I)diag(N)^{-1} for N = (I - Q)^{-1}
      transient_n = transient_states.size
      identity = NMatrix.float(transient_n, transient_n).diagonal!(1)
      n = (identity - transient_q).inverse
      n_diag = NMatrix[NArray[n] * NArray[identity]][nil, nil, 0, 0]
      (n - identity) * n_diag.inverse
    end
  end
end
