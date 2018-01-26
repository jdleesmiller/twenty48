# frozen_string_literal: true

require 'tmpdir'

require_relative 'helper'

class LayerTrancheBuilderTest < Twenty48NativeTest
  include Twenty48

  DISCOUNT = 0.95

  def find_summary_record(summary, row)
    summary.find do |record|
      record.sum == row[:sum] && record.max_value == row[:max_value]
    end
  end

  def test_build_2x2
    with_tmp_data do |data|
      max_states = 16
      model = data.game.new(board_size: 2, max_exponent: 5)
        .layer_model.new(max_depth: 0).mkdir!

      layer_builder = LayerBuilder.new(model, max_states)
      layer_builder.build_start_state_layers
      layer_builder.build

      layer_solver = LayerSolver.new(model, discount: DISCOUNT)
      layer_solver.solve

      tranche_builder_2 = LayerTrancheBuilder.new(
        model, layer_solver.solution_attributes, 1e-2
      )
      tranche_builder_2.build

      summary_2 = model.summarize_tranche_transient_pr(
        layer_solver.solution_attributes,
        tranche_builder_2.tranche_attributes
      )

      tranche_builder_0 = LayerTrancheBuilder.new(
        model, layer_solver.solution_attributes, 0
      )
      tranche_builder_0.build

      summary_0 = model.summarize_tranche_transient_pr(
        layer_solver.solution_attributes,
        tranche_builder_0.tranche_attributes
      )

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

      csv_options = {
        headers: true,
        converters: :numeric,
        header_converters: :symbol
      }
      CSV.parse(csv_from_fundamental_matrix, csv_options) do |row|
        observed_0 = find_summary_record(summary_0, row)
        assert_equal row[:num_states], observed_0[:num_states]
        assert_close row[:total_pr], observed_0[:total_pr]

        observed_2 = find_summary_record(summary_2, row)
        assert observed_2.nil? || observed_2[:total_pr] >= 1e-2
      end

      assert_equal 53, summary_0.map(&:num_states).sum
      assert_equal 44, summary_2.map(&:num_states).sum

      win_summary_0 = model.summarize_tranche_wins(
        layer_solver.solution_attributes,
        tranche_builder_0.tranche_attributes
      )

      loss_summary_0 = model.summarize_tranche_losses(
        layer_solver.solution_attributes,
        tranche_builder_0.tranche_attributes
      )

      #
      # Check absorbing probabilities against the sums from the MDP model:
      # {[0, 0, 0, 0]=>0.917112710928446, [0, 0, 0, 5]=>0.08288728907155415}
      #
      csv_from_aggregation = <<~CSV
        sum,max_value,outcome,num_states,total_pr
        18,3,lose,1,3.748875e-02
        26,4,lose,1,5.126375e-02
        30,4,lose,2,8.283602e-01
        38,5,win,2,6.042483e-02
        40,5,win,3,2.014161e-02
        42,5,win,3,2.237957e-03
        44,5,win,2,8.288729e-05
      CSV

      lose_pr = 0.0
      win_pr = 0.0
      CSV.parse(csv_from_aggregation, csv_options) do |row|
        if row[:outcome] == 'win'
          observed_0 = find_summary_record(win_summary_0, row)
          win_pr += observed_0.total_pr
        else
          observed_0 = find_summary_record(loss_summary_0, row)
          lose_pr += observed_0.total_pr
        end
        assert_close row[:num_states], observed_0.num_states
        assert_close row[:total_pr], observed_0.total_pr
      end
      assert_close 0.917112710928446, lose_pr
      assert_close 0.08288728907155415, win_pr
    end
  end

=begin
  def test_build_2x2_with_alternate_actions
    Dir.mktmpdir do |tmp|
      states_path = File.join(tmp, 'states')
      values_path = File.join(tmp, 'values')
      compacted_path = File.join(tmp, 'compacted')

      [states_path, values_path, compacted_path].each do |path|
        FileUtils.mkdir_p path
      end

      batch_size = 16
      max_exponent = 5
      board_size = 2
      params = {
        board_size: board_size,
        max_exponent: max_exponent,
        max_depth: 0,
        discount: DISCOUNT
      }
      valuer = NativeValuer.create(params)
      layer_builder = LayerBuilder.new(2, states_path, batch_size, valuer)
      layer_builder.build_start_state_layers
      layer_builder.build

      part_names = LayerPartName.glob(states_path)
      assert_equal 18, part_names.map(&:sum).uniq.size

      layer_solver = LayerSolver.new(
        2,
        states_path,
        values_path,
        valuer,
        alternate_action_tolerance: 1e-9
      )
      layer_solver.solve

      # Run the compactor.
      layer_compactor = LayerCompactor.new(
        2, states_path, batch_size, valuer,
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
      count = 0
      CSV.foreach(output_paths[0].in(compacted_path), csv_options) do |row|
        count += 1
        assert row[:transient_pr] > 1e-2
      end
      assert_equal 47, count
    end
  end
=end
end
