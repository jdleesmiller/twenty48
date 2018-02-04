# frozen_string_literal: true

require 'parallel'

module Twenty48
  #
  # Estimate transient and absorbing probabilities and moves to win/lose.
  #
  class Simulator
    include LayerStartStates

    Instance = Struct.new(:nybbles, :moves) do
      def to_s
        "#{nybbles.to_s(16)}@#{moves}"
      end

      def <=>(other)
        nybbles <=> other.nybbles
      end
    end

    def initialize(layer_model, solution_attributes,
      batch_size:, random:, use_alternate_actions:)
      @layer_model = layer_model
      @solution_attributes = solution_attributes
      @batch_size = batch_size
      @random = random
      @use_alternate_actions = use_alternate_actions
      @instances = []

      @transient_visits = make_histogram_hash
      @win_visits = make_histogram_hash
      @loss_visits = make_histogram_hash
      @wins = make_histogram_hash
      @losses = make_histogram_hash

      @board_size = layer_model.board_size
      @max_exponent = layer_model.max_exponent
    end

    attr_reader :layer_model
    attr_reader :solution_attributes
    attr_reader :batch_size
    attr_reader :random
    attr_reader :use_alternate_actions
    attr_reader :instances
    attr_reader :transient_visits
    attr_reader :win_visits
    attr_reader :loss_visits
    attr_reader :wins
    attr_reader :losses

    def run
      generate_start_states
      max_sum = layer_model.part.map(&:sum).max
      (4..max_sum).step(2).each do |sum|
        layer_model.part.where(sum: sum).each do |part|
          run_part(part)
        end
      end
      @instances.compact!
      raise 'not all games terminated' if @instances.any?
    end

    def transient_pr
      make_visit_prs(@transient_visits)
    end

    def win_pr
      make_visit_prs(@win_visits)
    end

    def loss_pr
      make_visit_prs(@loss_visits)
    end

    def moves_to_win_pr
      make_moves_prs(@wins)
    end

    def moves_to_lose_pr
      make_moves_prs(@losses)
    end

    private

    def generate_start_states
      prs = LayerStateProbabilities.new
      find_start_state_probabilities(@board_size, prs)
      cdf = make_cdf(prs.flatten)
      @instances = Array.new(batch_size) do
        nybbles = sample(cdf)
        @transient_visits[nybbles] += 1
        Instance.new(nybbles, 0)
      end
      # p instances.map(&:to_s)
    end

    def run_part(part)
      solution = part.solution.find_by(solution_attributes)
      return unless solution&.policy&.exist?
      state_reader = VByteReader.new(part.states_vbyte.to_s)
      policy_reader = PolicyReader.new(solution.policy.to_s)
      alternate_action_reader = make_alternate_action_reader(solution)
      instances.compact!
      instances.sort!
      apply_policy(part, state_reader, policy_reader, alternate_action_reader)
      # p instances.map(&:to_s)
    end

    def make_alternate_action_reader(solution)
      return nil unless use_alternate_actions
      AlternateActionReader.new(solution.alternate_actions.to_s)
    end

    def apply_policy(part, state_reader, policy_reader, alternate_action_reader)
      policy_state = 0
      action = nil
      alternate_actions = nil
      (0...instances.size).each do |index|
        state_nybbles = instances[index].nybbles
        state = NativeState.create_from_nybbles(@board_size, state_nybbles)
        next unless state_in_part(state, part)

        while policy_state != state_nybbles
          policy_state = state_reader.read
          raise 'out of policy states' if policy_state == 0
          action = policy_reader.read

          alternate_actions = alternate_action_reader&.read(action)
        end

        if alternate_actions
          move_with_alternate_actions(index, state, alternate_actions)
        else
          move(index, state, action)
        end
      end
    end

    def state_in_part(state, part)
      state.max_value == part.max_value && state.sum == part.sum
    end

    def move_with_alternate_actions(index, state, alternate_actions)
      actions = alternate_actions.each_index.select { |i| alternate_actions[i] }
      action = actions.sample(random: random)
      move(index, state, action)
    end

    def move(index, state, action)
      move_state = state.move(action)
      num_available = move_state.cells_available
      new_tile_index = random.rand(num_available)
      new_tile_value = random.rand < 0.1 ? 2 : 1
      new_state = move_state.place(new_tile_index, new_tile_value)
      finish_move(index, new_state)
    end

    def finish_move(index, new_state)
      new_state_nybbles = new_state.get_nybbles
      instance = instances[index]
      instance.moves += 1

      if new_state.max_value >= @max_exponent
        @win_visits[new_state_nybbles] += 1
        @wins[instance.moves] += 1
        instances[index] = nil
      elsif new_state.lose
        @loss_visits[new_state_nybbles] += 1
        @losses[instance.moves] += 1
        instances[index] = nil
      else
        @transient_visits[new_state_nybbles] += 1
        instance.nybbles = new_state_nybbles
      end
    end

    def make_histogram_hash
      Hash.new do |h, k|
        h[k] = 0
      end
    end

    def make_cdf(hash)
      total = 0.0
      result = hash.map do |state, pr|
        total += pr
        [total, state]
      end
      raise 'cdf does not sum to one' unless (1 - total) < 1e-9
      result
    end

    def sample(cdf)
      r = @random.rand
      pair = cdf.find { |pr, _value| r <= pr }
      pair[1]
    end

    def make_visit_prs(visits)
      n = batch_size.to_f
      visits.keys.sort.map do |nybbles|
        [nybbles.to_s(16), visits[nybbles] / n]
      end
    end

    def make_moves_prs(moves)
      n = batch_size.to_f
      moves.keys.sort.map do |count|
        [count, moves[count] / n]
      end
    end
  end
end
