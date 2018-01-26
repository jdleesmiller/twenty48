# frozen_string_literal: true

module Twenty48
  #
  # Calculate transient and absorbing probabilities and record which states are
  # more probable than a given threshold.
  #
  class LayerTrancheBuilder
    def initialize(layer_model, solution_attributes, threshold)
      @layer_model = layer_model
      @solution_attributes = solution_attributes
      @threshold = threshold
      @builder = NativeLayerTrancheBuilder.create(
        layer_model.board_size, layer_model.max_exponent, threshold
      )
    end

    attr_reader :builder
    attr_reader :layer_model
    attr_reader :solution_attributes
    attr_reader :threshold

    def build
      builder.add_start_state_probabilities
      max_sum = layer_model.part.map(&:sum).max + 4
      (4..max_sum).step(2).each do |sum|
        parts = layer_model.part.where(sum: sum)
        parts.each { |part| process_part(part) }
        process_wins(sum) if builder.have_wins(sum)
        (3...layer_model.max_exponent).each do |max_value|
          process_losses(sum, max_value) if builder.have_losses(sum, max_value)
        end
      end
    end

    def tranche_attributes
      { threshold: threshold }
    end

    private

    def process_part(part)
      return unless part.states_vbyte.exist? # may be wins/losses only
      solution = part.solution.find_by(solution_attributes)
      raise "no solution for #{part}" if solution.nil?
      tranche = solution.tranche.new(tranche_attributes).mkdir!
      builder.run(
        part.sum, part.max_value,
        part.states_vbyte.to_s, solution.policy.to_s,
        tranche.bit_set.to_s, tranche.transient_pr.to_s
      )
    end

    def new_tranche(layer_sum, max_value)
      layer_model.part.new(sum: layer_sum, max_value: max_value)
        .solution.new(solution_attributes)
        .tranche.new(tranche_attributes).mkdir!
    end

    def process_wins(layer_sum)
      tranche = new_tranche(layer_sum, layer_model.max_exponent)
      builder.finish_wins(layer_sum, tranche.wins.to_s)
    end

    def process_losses(layer_sum, max_value)
      tranche = new_tranche(layer_sum, max_value)
      builder.finish_losses(layer_sum, max_value, tranche.losses.to_s)
    end
  end
end
