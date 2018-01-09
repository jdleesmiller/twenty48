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

    def initialize(board_size, layer_folder, values_folder, valuer,
      alternate_action_tolerance: nil, end_layer_sum: nil, verbose: false)
      @board_size = board_size
      @layer_folder = layer_folder
      @values_folder = values_folder
      @valuer = valuer
      @alternate_action_tolerance = alternate_action_tolerance
      @end_layer_sum = end_layer_sum || find_max_layer_sum
      @solver = NativeLayerSolver.create(board_size, valuer)
      @verbose = verbose

      raise "not enough layers: #{end_layer_sum}" if
        @end_layer_sum.nil? || @end_layer_sum < 8
    end

    attr_reader :board_size
    attr_reader :layer_folder
    attr_reader :values_folder
    attr_reader :valuer
    attr_reader :alternate_action_tolerance
    attr_reader :end_layer_sum

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
            layer_part_values_pathname(end_layer_sum, max_value)
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

    private

    def load_values(sum, max_value)
      pathname_1_0, pathname_1_1 = next_value_pathnames(sum + 2, max_value)
      pathname_2_0, pathname_2_1 = next_value_pathnames(sum + 4, max_value)
      @solver.load(pathname_1_0, pathname_1_1, pathname_2_0, pathname_2_1)
    end

    def next_value_pathnames(next_sum, max_value)
      next_max_values = find_max_values(next_sum)
      if next_max_values.member?(max_value)
        pathname_0 = layer_part_values_pathname(next_sum, max_value)
        pathname_0 = nil if file_size_if_exists(pathname_0) == 0
      end
      if next_max_values.member?(max_value + 1)
        pathname_1 = layer_part_values_pathname(next_sum, max_value + 1)
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
        states_pathname = layer_part_pathname(sum, max_value)
        policy_pathname = layer_fragment_policy_pathname(sum, max_value, index)
        values_pathname = layer_fragment_values_pathname(sum, max_value, index)
        alternate_action_pathname = layer_fragment_alternate_action_pathname(
          sum, max_value, index
        )
        vbyte_reader = VByteReader.new(states_pathname, offset, previous,
          batch_size)
        solution_writer = SolutionWriter.new(
          policy_pathname,
          values_pathname,
          alternate_action_pathname,
          alternate_action_tolerance || 0.0
        )
        @solver.solve(vbyte_reader, sum, max_value, solution_writer)
        STDOUT.write('.') if @verbose
        GC.start
      end
      puts if @verbose # put a line break after the dots from the fragments
    end

    def reduce_layer_part(sum, max_value)
      log_reduce_layer(sum, max_value)

      concatenate(
        find_layer_fragments(sum, max_value, LayerFragmentValuesName),
        layer_part_values_pathname(sum, max_value)
      )
      concatenate(
        find_layer_fragments(sum, max_value, LayerFragmentPolicyName),
        layer_part_policy_pathname(sum, max_value)
      )

      return if alternate_action_tolerance.nil?
      concatenate(
        find_layer_fragments(sum, max_value, LayerFragmentAlternateActionName),
        layer_part_alternate_action(sum, max_value)
      )
    end

    def find_layer_fragments(sum, max_value, klass)
      files = klass.glob(values_folder).select do |name|
        name.sum == sum && name.max_value == max_value
      end
      files = files.sort_by { |name| [name.sum, name.max_value, name.batch] }
      files.map { |name| name.in(values_folder) }
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

    def layer_fragment_values_pathname(sum, max_value, batch)
      LayerFragmentValuesName.new(
        sum: sum, max_value: max_value, batch: batch
      ).in(values_folder)
    end

    def layer_fragment_alternate_action_pathname(sum, max_value, batch)
      return nil if alternate_action_tolerance.nil?
      LayerFragmentAlternateActionName.new(
        sum: sum, max_value: max_value, batch: batch
      ).in(values_folder)
    end

    def layer_fragment_policy_pathname(sum, max_value, batch)
      LayerFragmentPolicyName.new(
        sum: sum, max_value: max_value, batch: batch
      ).in(values_folder)
    end

    def layer_part_values_pathname(sum, max_value)
      LayerPartValuesName.new(
        sum: sum, max_value: max_value
      ).in(values_folder)
    end

    def layer_part_policy_pathname(sum, max_value)
      LayerPartPolicyName.new(
        sum: sum, max_value: max_value
      ).in(values_folder)
    end

    def layer_part_alternate_action(sum, max_value)
      LayerPartAlternateActionName.new(
        sum: sum, max_value: max_value
      ).in(values_folder)
    end

    def find_max_layer_sum
      LayerPartName.glob(layer_folder).map(&:sum).max
    end

    def check_batch_size(batch_size)
      return if alternate_action_tolerance.nil?
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
