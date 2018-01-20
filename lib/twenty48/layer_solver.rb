# frozen_string_literal: true

require 'parallel'
require 'tmpdir'

module Twenty48
  #
  # Solver that works backwards through the layers constructed by the
  # LayerBuilder. It also uses a map-reduce approach: we break the layer that
  # is being solved into batches in order to parallelise the solve.
  #
  # The main output is a bit-packed policy file for each layer. We also generate
  # a value file for each layer as we're solving, but due to the size of the
  # value layers, there is an option to discard them. (TODO)
  #
  # Want to go down by sum and down by max_value. So, we start with the max
  # sum and max value. All successors must resolve. Same is true for all other
  # max values in the max sum layer.
  #
  # So, then we
  #
  class LayerSolver
    include Layers

    def initialize(layer_model,
      discount: nil,
      alternate_action_tolerance: -1,
      end_layer_sum: nil,
      verbose: false)
      @layer_model = layer_model
      @discount = discount
      @valuer = layer_model.create_native_valuer(discount: discount)
      @alternate_action_tolerance = alternate_action_tolerance
      @end_layer_sum = end_layer_sum || find_max_layer_sum
      @solver = NativeLayerSolver.create(layer_model.board_size, valuer)
      @verbose = verbose

      raise "not enough layers: #{end_layer_sum}" if
        @end_layer_sum.nil? || @end_layer_sum < 8
    end

    attr_reader :layer_model
    attr_reader :discount
    attr_reader :valuer
    attr_reader :alternate_action_tolerance
    attr_reader :end_layer_sum

    def board_size
      layer_model.board_size
    end

    def solution_attributes
      {
        discount: discount,
        alternate_action_tolerance: alternate_action_tolerance
      }
    end

    def solve
      layer_sum = end_layer_sum
      while layer_sum >= 4
        # Run a GC to make sure we close file handles in VByteReaders.
        GC.start

        solve_layer(layer_sum)
        layer_sum -= 2
      end
    end

    #
    # If we have not finished building, we can't really solve, but we can run
    # the solve with fake values for the last two layers in order to test that
    # the preceding layers are solvable (not missing states, corrupt, etc.).
    #
    def prepare_to_check_solve(fake_value = 0.01)
      2.times do
        find_max_values(end_layer_sum).each do |max_value|
          log format('faking values: %d-%x', end_layer_sum, max_value)
          vbyte_reader = VByteReader.new(
            layer_part_pathname(end_layer_sum, max_value)
          )
          @solver.generate_values_for_check(
            vbyte_reader,
            fake_value,
            new_solution(end_layer_sum, max_value).values.to_s
          )
        end
        @end_layer_sum -= 2
      end
    end

    def solve_layer(sum)
      find_max_values(sum).each do |max_value|
        load_values(sum, max_value)
        solve_layer_part(sum, max_value)
        reduce_layer_part(sum, max_value)
      end
    end

    def new_solution(sum, max_value)
      new_part(sum, max_value).solution.new(solution_attributes)
    end

    def new_fragment(sum, max_value, batch)
      new_solution(sum, max_value).fragment.new(batch: batch)
    end

    private

    def load_values(sum, max_value)
      pathname_1_0, pathname_1_1 = next_value_pathnames(sum + 2, max_value)
      pathname_2_0, pathname_2_1 = next_value_pathnames(sum + 4, max_value)
      @solver.load(pathname_1_0, pathname_1_1, pathname_2_0, pathname_2_1)
    end

    def next_value_pathnames(next_sum, max_value)
      next_max_values = find_max_values(next_sum)
      if next_max_values.member?(max_value)
        pathname_0 = new_solution(next_sum, max_value).values.to_s
        pathname_0 = nil if file_size_if_exists(pathname_0) == 0
      end
      if next_max_values.member?(max_value + 1)
        pathname_1 = new_solution(next_sum, max_value + 1).values.to_s
        pathname_1 = nil if file_size_if_exists(pathname_1) == 0
      end
      [pathname_0, pathname_1]
    end

    def solve_layer_part(sum, max_value)
      batches = make_layer_part_batches(sum, max_value)
      log_solve_layer(sum, max_value, batches.size)
      GC.start
      Parallel.each(batches) do |index, offset, previous, batch_size|
        check_batch_size(batch_size)
        states_pathname = layer_part_states_pathname(sum, max_value)
        vbyte_reader = VByteReader.new(states_pathname, offset, previous,
          batch_size)
        fragment = new_fragment(sum, max_value, index).mkdir!
        alternate_action_pathname = fragment.alternate_actions.to_s if
          alternate_action_tolerance >= 0
        solution_writer = SolutionWriter.new(
          fragment.policy.to_s,
          fragment.values.to_s,
          alternate_action_pathname,
          alternate_action_tolerance
        )
        @solver.solve(vbyte_reader, sum, max_value, solution_writer)
        STDOUT.write('.') if @verbose
        GC.start
      end
      puts if @verbose # put a line break after the dots from the fragments
    end

    def reduce_layer_part(sum, max_value)
      log_reduce_layer(sum, max_value)

      fragments = new_solution(sum, max_value).fragment.all
      concatenate(
        fragments.map(&:values).map(&:to_s),
        new_solution(sum, max_value).values.to_s
      )
      concatenate(
        fragments.map(&:policy).map(&:to_s),
        new_solution(sum, max_value).policy.to_s
      )

      if alternate_action_tolerance >= 0
        concatenate(
          fragments.map(&:alternate_actions).map(&:to_s),
          new_solution(sum, max_value).alternate_actions.to_s
        )
      end

      fragments.each(&:remove_if_empty)
    end

    def concatenate(input_pathnames, output_pathname)
      return if input_pathnames.empty?

      first_pathname = input_pathnames.shift
      FileUtils.mv first_pathname, output_pathname

      input_pathnames.each do |input_pathname|
        system %(cat "#{input_pathname}" >> "#{output_pathname}")
        FileUtils.rm input_pathname
      end
    end

    def find_max_layer_sum
      layer_model.part.map(&:sum).max
    end

    def check_batch_size(batch_size)
      return if alternate_action_tolerance < 0
      # Otherwise we cannot concatenate the alternate actions as binary files.
      raise 'batch size must be multiple of 16' unless batch_size % 16 == 0
    end

    def log_solve_layer(layer_sum, max_value, num_batches)
      log format('solve %d-%x: %d states (%d batches)',
        layer_sum, max_value, count_states(layer_sum, max_value), num_batches)
    end

    def log_reduce_layer(layer_sum, max_value)
      log format('reduce %d-%x', layer_sum, max_value)
    end
  end
end
