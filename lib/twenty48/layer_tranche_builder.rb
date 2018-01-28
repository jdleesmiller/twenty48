# frozen_string_literal: true

module Twenty48
  #
  # Calculate transient and absorbing probabilities and record which states are
  # more probable than a given threshold.
  #
  class LayerTrancheBuilder
    include Layers
    include LayerStartStates

    def initialize(layer_model, solution_attributes, tranche_attributes,
      verbose: false)
      @layer_model = layer_model
      @solution_attributes = solution_attributes
      @tranche_attributes = tranche_attributes
      @verbose = verbose
    end

    attr_reader :builder
    attr_reader :layer_model
    attr_reader :solution_attributes
    attr_reader :tranche_attributes

    def build
      write_start_states
      max_sum = layer_model.part.map(&:sum).max + 4
      (4..max_sum).step(2).each do |sum|
        parts = layer_model.part.where(sum: sum)
        parts.each { |part| process_part(part) }
        process_wins(sum)
        (3...layer_model.max_exponent).each do |max_value|
          process_losses(sum, max_value)
        end
      end
    end

    def threshold
      tranche_attributes[:threshold]
    end

    def alternate_action_tolerance
      solution_attributes[:alternate_action_tolerance]
    end

    private

    def write_start_states
      prs = LayerStateProbabilities.new
      find_start_state_probabilities(layer_model.board_size, prs)
      prs.each_sum_max_value do |sum, max_value, state_prs|
        part = layer_model.part.find_by(sum: sum, max_value: max_value)
        solution = part.solution.find_by(solution_attributes)
        tranche = solution.tranche.new(tranche_attributes).mkdir!

        parent = \
          if sum == 4
            tranche # layer sum 4 is just start states
          else
            tranche.output_fragment.new(
              input_sum: 0, input_max_value: 0, batch: 0
            )
          end

        File.open(parent.transient.mkdir!.to_s, 'wb') do |file|
          state_prs.sort.each do |nybbles, pr|
            file.write([nybbles, pr].pack('QD'))
          end
        end
      end
    end

    def process_part(part)
      log part.to_s
      return unless part.states_vbyte.exist? # may be wins/losses only
      solution = part.solution.find_by(solution_attributes)
      raise "no solution for #{part}" if solution.nil?
      tranche = solution.tranche.new(tranche_attributes).mkdir!
      prepare(tranche)
      map(part, tranche)
      GC.start
      reduce(tranche)
    end

    def prepare(tranche)
      %i[transient wins losses].each do |file|
        files = tranche.output_fragment.map(&file).select(&:exist?)
        next if files.none?
        log "prepare #{file}"
        Twenty48.merge_state_probabilities(
          files.map(&:to_s),
          tranche.send(file).to_s
        )
      end
      tranche.output_fragment.each(&:destroy!)
    end

    def map(part, tranche)
      log 'map'
      transient = tranche.transient
      return unless transient.exist?
      builder = NativeLayerTrancheBuilder.create(
        layer_model.board_size, layer_model.max_exponent, threshold,
        part.sum, part.max_value,
        transient.to_s
      )
      jobs = make_map_jobs(builder, part, tranche)
      GC.start
      Parallel.each(jobs, &:run)
    end

    def make_map_jobs(builder, part, tranche)
      batches = make_layer_part_batches(part.sum, part.max_value)
      batches.map do |index, byte_offset, previous, batch_size|
        check_batch_size_for_bit_set(batch_size)
        TrancheJob.new(
          builder, tranche, index, byte_offset, previous, batch_size
        )
      end
    end

    def reduce(tranche)
      log 'reduce'
      concatenate(
        tranche.fragment.map(&:bit_set).map(&:to_s),
        tranche.bit_set.to_s
      )
      concatenate(
        tranche.fragment.map(&:transient_pr).map(&:to_s),
        tranche.transient_pr.to_s
      )
      tranche.fragment.each(&:destroy!)
      tranche.transient.destroy!
      rmdir_if_empty(tranche)
    end

    def rmdir_if_empty(dir)
      parent = dir.parent
      FileUtils.rmdir(dir.to_s)
      rmdir_if_empty(parent) if parent
    rescue Errno::ENOTEMPTY, Errno::ENOENT
      nil # ignore
    end

    TrancheJob = Struct.new(
      :builder, :tranche, :index, :byte_offset, :previous, :batch_size
    ) do
      def run
        builder.build(
          make_vbyte_reader,
          make_policy_reader,
          make_alternate_action_reader,
          fragment.bit_set.to_s,
          fragment.transient_pr.to_s
        )
        builder.write(
          transient_pathname(1, 0), transient_pathname(1, 1),
          transient_pathname(2, 0), transient_pathname(2, 1),
          loss_pathname(1, 0), loss_pathname(1, 1),
          loss_pathname(2, 0), loss_pathname(2, 1),
          win_pathname(1), win_pathname(2)
        )
      end

      private

      def make_vbyte_reader
        VByteReader.new(
          part.states_vbyte.to_s, byte_offset, previous, batch_size
        )
      end

      def make_policy_reader
        reader = PolicyReader.new(solution.policy.to_s)
        reader.skip(index * batch_size)
        reader
      end

      def make_alternate_action_reader
        return nil unless tranche.alternate_actions
        alternate_actions = solution.alternate_actions
        raise 'no alternate actions' unless alternate_actions&.exist?
        reader = AlternateActionReader.new(alternate_actions.to_s)
        reader.skip(index * batch_size)
        reader
      end

      def model
        part.parent
      end

      def part
        solution.parent
      end

      def solution
        tranche.parent
      end

      def fragment
        tranche.fragment.new(batch: index).mkdir!
      end

      def output_fragment(step, jump)
        output_part = model.part.new(
          sum: part.sum + step * 2,
          max_value: part.max_value + jump
        )
        output_solution = output_part.solution.new(solution.to_h)
        output_tranche = output_solution.tranche.new(tranche.to_h)
        output_tranche.output_fragment.new(
          input_sum: part.sum,
          input_max_value: part.max_value,
          batch: index
        ).mkdir!
      end

      def transient_pathname(step, jump)
        output_fragment(step, jump).transient.to_s
      end

      def loss_pathname(step, jump)
        output_fragment(step, jump).losses.to_s
      end

      def win_pathname(step)
        output_fragment(step, 1).wins.to_s
      end
    end

    def new_tranche(layer_sum, max_value)
      layer_model.part.new(sum: layer_sum, max_value: max_value)
        .solution.new(solution_attributes)
        .tranche.new(tranche_attributes)
    end

    def process_wins(layer_sum)
      tranche = new_tranche(layer_sum, layer_model.max_exponent)
      prepare(tranche)
      rmdir_if_empty(tranche)
    end

    def process_losses(layer_sum, max_value)
      tranche = new_tranche(layer_sum, max_value)
      prepare(tranche)
      rmdir_if_empty(tranche)
    end
  end
end
