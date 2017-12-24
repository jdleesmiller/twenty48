# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class LayerTrancheBuilderTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

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
        compacted_path, board_size, [3, 6], 2
      )
      tranche_builder.build

      output_paths = LayerTrancheName.glob(compacted_path)
      assert_equal 1, output_paths.size
      tranche_policy = {}
      CSV.foreach(output_paths[0].in(compacted_path), headers: true) do |row|
        nybbles = row['state'].to_i(16)
        state = NativeState.create_from_nybbles(board_size, nybbles)
        tranche_policy[state] = row['action'].to_i
        assert row['transient_pr'].to_f > 1e-2
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
      # result <- merge(t3, merge(t6, t0, all=TRUE), all=TRUE)
      # result <- result[order(result$sum, result$max_value),]
      # write.csv(file='check_metrics.csv', result, row.names=FALSE)
      #
      tranche_metrics = File.read(tranche_builder.metrics_pathname)
      assert_equal <<~CSV, tranche_metrics
        sum,max_value,num_states_3,num_states_6,num_states
        4,1,2,2,2
        6,1,1,1,1
        6,2,2,2,2
        8,2,4,4,4
        10,2,3,3,3
        12,2,2,2,2
        12,3,2,2,2
        14,2,1,1,1
        14,3,4,4,4
        16,3,3,3,3
        18,3,2,2,2
        20,3,3,3,3
        20,4,2,2,2
        22,3,1,1,1
        22,4,4,4,4
        24,3,1,1,1
        24,4,3,3,3
        26,4,3,3,3
        28,4,4,4,4
        32,4,1,1,1
        34,4,1,1,1
        36,4,2,2,2
        38,4,1,1,1
        40,4,0,1,1
      CSV

      tranche_metrics = {}
      CSV.foreach(tranche_builder.metrics_pathname, headers: true) do |row|
        tranche_metrics[{
          sum: row['sum'].to_i,
          max_value: row['max_value'].to_i
        }] = row
      end

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
          num_tranche_states = tranche_metrics[key]['num_states'].to_i
          assert_equal num_tranche_states, compacted_states.size
        end
      end
    end
  end
end
