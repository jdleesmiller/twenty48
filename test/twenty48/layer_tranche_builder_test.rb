# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class LayerTrancheBuilderTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  def metrics_key(row)
    { sum: row[:sum], max_value: row[:max_value] }
  end

  def test_build_2x2
    Dir.mktmpdir do |tmp|
      states_path = File.join(tmp, 'states')
      values_path = File.join(tmp, 'values')
      compacted_path = File.join(tmp, 'compacted')

      [states_path, values_path, compacted_path].each do |path|
        FileUtils.mkdir_p path
      end

      max_states = 4
      max_exponent = 5
      board_size = 2
      params = {
        board_size: board_size,
        max_exponent: max_exponent,
        max_depth: 0,
        discount: DISCOUNT
      }
      valuer = NativeValuer.create(params)
      layer_builder = LayerBuilder.new(2, states_path, max_states, valuer)
      layer_builder.build_start_state_layers
      layer_builder.build

      part_names = LayerPartName.glob(states_path)
      assert_equal 18, part_names.map(&:sum).uniq.size

      layer_solver = LayerSolver.new(
        2,
        states_path,
        values_path,
        valuer
      )
      layer_solver.solve

      # 2 states at 16B / state
      values_4_file = LayerPartValuesName.glob(values_path)
        .find { |name| name.sum == 4 && name.max_value == 1 }
      assert_equal 32, File.size(values_4_file.in(values_path))

      # Run the compactor.
      layer_compactor = LayerCompactor.new(
        2, states_path, max_states, valuer,
        values_path, compacted_path
      )
      layer_compactor.build_start_state_layers
      layer_compactor.build

      # Now run the tranche builder.
      tranche_builder = LayerTrancheBuilder.new(
        compacted_path, board_size, max_exponent, [3, 6], 2
      )
      tranche_builder.build

      output_paths = LayerTrancheName.glob(compacted_path)
      assert_equal 1, output_paths.size

      csv_options = {
        headers: true,
        converters: :numeric,
        header_converters: :symbol
      }
      tranche_policy = {}
      CSV.foreach(output_paths[0].in(compacted_path), csv_options) do |row|
        nybbles = row[:state].to_s.to_i(16) # decimal to hexadecimal
        state = NativeState.create_from_nybbles(board_size, nybbles)
        tranche_policy[state] = row[:action]
        assert row[:transient_pr] > 1e-2
      end

      #
      # Check against the results obtained from the fundamental matrix via
      # bin/markov_chain_full. Results generated (with minor edits) from R:
      # t <- read.csv('check.csv')
      # t0 <- aggregate(cbind(num_states=state) ~ sum + max_value,
      #   subset(t, transient_pr > 0), length)
      # t3 <- aggregate(cbind(num_states_3=state) ~ sum + max_value,
      #   subset(t, transient_pr > 1e-3), length)
      # t6 <- aggregate(cbind(num_states_6=state) ~ sum + max_value,
      #   subset(t, transient_pr > 1e-6), length)
      # tp <- aggregate(cbind(total_pr=transient_pr) ~ sum + max_value, t, sum)
      # result <- merge(t3, merge(t6, merge(t0, tp,
      #   all=TRUE), all=TRUE), all=TRUE)
      # result <- result[order(result$sum, result$max_value),]
      # write.csv(file='check_metrics.csv', result, row.names=FALSE)
      #
      tranche_metrics = {}
      CSV.foreach(tranche_builder.metrics_pathname, csv_options) do |row|
        tranche_metrics[metrics_key(row)] = row
      end

      csv_from_fundamental_matrix = <<~CSV
        "sum","max_value","num_states_3","num_states_6","num_states","total_pr"
        4,1,2,2,2,0.81
        6,1,1,1,1,0.729
        6,2,2,2,2,0.18
        8,2,4,4,4,0.9091
        10,2,3,3,3,0.90909
        12,2,2,2,2,0.4631455
        12,3,2,2,2,0.4459455
        14,2,1,1,1,0.0413595
        14,3,4,4,4,0.8677314
        16,3,3,3,3,0.90909091
        18,3,2,2,2,0.87160216275
        20,3,3,3,3,0.84756324835
        20,4,2,2,2,0.027787789125
        22,3,1,1,1,0.162803333925
        22,4,4,4,4,0.7121728160775
        24,3,1,1,1,0.008747849975
        24,4,3,3,3,0.86626578877475
        26,4,3,3,3,0.823746140933963
        28,4,4,4,4,0.828872890715542
        32,4,1,1,1,0.0828872890715542
        34,4,1,1,1,0.0745985601643987
        36,4,2,2,2,0.0754274330551142
        38,4,1,1,1,0.0149197120328797
        40,4,0,1,1,0.000828872890715542
      CSV

      CSV.parse(csv_from_fundamental_matrix, csv_options) do |row|
        observed_row = tranche_metrics[metrics_key(row)]
        %i[num_states_3 num_states_6 num_states].each do |column|
          assert_equal row[column], observed_row[column]
        end
        assert_close row[:total_pr], observed_row[:total_pr]
      end

      #
      # Check absorbing probabilities against the sums from the MDP model:
      # {[0, 0, 0, 0]=>0.917112710928446, [0, 0, 0, 5]=>0.08288728907155415}
      #
      lose_pr = 0.0
      win_pr = 0.0
      absorbing_states_csv = tranche_builder.absorbing_states_pathname
      CSV.foreach(absorbing_states_csv, csv_options) do |row|
        nybbles = row[:state].to_s.to_i(16) # decimal to hexadecimal
        state = NativeState.create_from_nybbles(board_size, nybbles)
        if state.max_value >= max_exponent
          win_pr += row[:pr]
        else
          lose_pr += row[:pr]
        end
      end
      assert_close 0.917112710928446, lose_pr
      assert_close 0.08288728907155415, win_pr

      LayerPartName.glob(states_path).each do |name|
        key = { sum: name.sum, max_value: name.max_value }
        policy = LayerPartPolicyName.new(key)
        compacted_states = name.read_states(board_size, folder: compacted_path)
        compacted_policy = PolicyReader.read(
          policy.in(compacted_path), compacted_states.size
        )

        compacted_states.zip(compacted_policy).each do |state, action|
          next unless tranche_policy.key?(state)
          assert_equal tranche_policy[state], action
        end

        if tranche_metrics.key?(key)
          num_tranche_states = tranche_metrics[key][:num_states].to_i
          assert_equal num_tranche_states, compacted_states.size
        end
      end
    end
  end
end