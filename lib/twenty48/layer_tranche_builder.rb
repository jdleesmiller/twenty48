# frozen_string_literal: true

module Twenty48
  LayerTrancheName = KeyValueName.new do |n|
    n.key :threshold, type: Numeric
    n.extension :csv
  end

  TransientProbabilityMetrics = Struct.new(:count, :log_pr_sum)

  #
  # Accumulate state probabilities by sum and max value.
  #
  class StateProbabilities
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
  end

  #
  # Take a compacted policy and compute transient probabilities to generate:
  #
  # 1. Statistics on the transient probabilities in each sum layer, and
  # 2. Optionally, a CSV policy for a given transient probability threshold.
  #
  class LayerTrancheBuilder
    def initialize(path, board_size, max_exponent,
      metrics_thresholds, output_threshold)
      @path = path
      @board_size = board_size
      @max_exponent = max_exponent
      @metrics_thresholds = metrics_thresholds
      @output_threshold = output_threshold

      @transient_probabilities = StateProbabilities.new
      @wins = StateProbabilities.new
      @losses = StateProbabilities.new

      @threshold_counts = make_zero_threshold_counts
    end

    attr_reader :path
    attr_reader :board_size
    attr_reader :max_exponent
    attr_reader :transient_probabilities
    attr_reader :wins
    attr_reader :losses
    attr_reader :metrics_thresholds
    attr_reader :output_threshold
    attr_reader :threshold_counts

    def metrics_pathname
      File.join(path, 'tranche_metrics.csv')
    end

    def absorbing_pathname
      File.join(path, 'absorbing_metrics.csv')
    end

    def output_pathname
      LayerTrancheName.new(threshold: output_threshold).in(path)
    end

    def output_threshold_pr
      10**-output_threshold
    end

    def build
      add_start_states
      CSV.open(metrics_pathname, 'w') do |metrics_csv|
        metrics_csv << %w[sum max_value] + metrics_threshold_names +
          %w[total_pr]
        CSV.open(absorbing_pathname, 'w') do |absorbing_csv|
          absorbing_csv << %w[sum max_value outcome num_states total_pr]
          CSV.open(output_pathname, 'w') do |output_csv|
            output_csv << %w[state action transient_pr]
            part_names = LayerPartName.glob(path).sort_by do |part|
              [part.sum, part.max_value]
            end
            part_names.each do |part_name|
              write_absorbing_counts(
                part_name.sum, part_name.max_value, absorbing_csv
              )
              process_part(metrics_csv, output_csv, part_name)
            end
            write_absorbing_counts(
              Float::INFINITY, Float::INFINITY, absorbing_csv
            )
          end
        end
      end
    end

    private

    def add_start_states
      empty_state = NativeState.create([0] * board_size**2)
      empty_state.random_transitions.each do |one_tile_state, pr0|
        one_tile_state.random_transitions.each do |two_tile_state, pr1|
          transient_probabilities.add(two_tile_state, pr0 * pr1)
        end
      end
    end

    def metrics_threshold_names
      metrics_thresholds.map { |threshold| "num_states_#{threshold}" } +
        %w[num_states]
    end

    def process_part(metrics_csv, output_csv, part_name)
      total_pr = 0.0
      counts = make_zero_threshold_counts
      each_part_state_action(part_name) do |state, action|
        state_pr = transient_probabilities.find(state)

        state.move(action).random_transitions.each do |successor, pr|
          successor_pr = state_pr * pr
          if successor.max_value >= max_exponent
            wins.add(successor, successor_pr)
          elsif successor.lose
            losses.add(successor, successor_pr)
          else
            transient_probabilities.add(successor, successor_pr)
          end
        end

        if state_pr > output_threshold_pr
          output_csv << [state_name(state), action, state_pr]
        end

        update_counts(counts, state_pr)
        total_pr += state_pr
      end
      write_counts(part_name, metrics_csv, counts, total_pr)
      transient_probabilities.clear(part_name.sum, part_name.max_value)
    end

    def each_part_state_action(part_name)
      policy_name = LayerPartPolicyName.new(
        sum: part_name.sum,
        max_value: part_name.max_value
      )
      policy_reader = PolicyReader.new(policy_name.in(path))
      Twenty48.each_state_vbyte(board_size, part_name.in(path)) do |state|
        action = policy_reader.read
        yield state, action
      end
    end

    def metrics_threshold_prs
      metrics_thresholds.map { |threshold| 10**-threshold }
    end

    def make_zero_threshold_counts
      Hash[metrics_threshold_prs.map { |pr| [pr, 0] } + [[0.0, 0]]]
    end

    def update_counts(counts, state_pr)
      counts.each_key do |threshold_pr|
        counts[threshold_pr] += 1 if state_pr >= threshold_pr
      end
    end

    def write_counts(part_name, metrics_csv, counts, total_pr)
      row = [part_name.sum, part_name.max_value]
      row += metrics_threshold_prs.map { |pr| counts[pr] }
      row += [counts[0.0], total_pr]
      metrics_csv << row
    end

    def state_name(state)
      state.get_nybbles.to_s(16)
    end

    def write_absorbing_counts(max_sum, max_max_value, absorbing_csv)
      outcomes = %i[win lose]
      [wins, losses].zip(outcomes).each do |prs, outcome|
        prs.each_sum_max_value do |sum, max_value, state_prs|
          break if ([sum, max_value] <=> [max_sum, max_max_value]) > 0
          absorbing_csv << [
            sum,
            max_value,
            outcome,
            state_prs.size,
            state_prs.values.sum
          ]
          prs.clear(sum, max_value)
        end
      end
    end
  end
end
