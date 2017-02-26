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
      end_layer_sum: nil, verbose: false)
      @layer_folder = layer_folder
      @values_folder = values_folder
      @end_layer_sum = end_layer_sum || find_max_layer_sum
      @solver = NativeLayerSolver.create(board_size, valuer)
      @verbose = verbose

      raise "not enough layers: #{end_layer_sum}" if @end_layer_sum < 8
    end

    attr_reader :layer_folder
    attr_reader :values_folder
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
      if next_sum <= end_layer_sum
        next_max_values = find_max_values(next_sum)
        if next_max_values.member?(max_value)
          pathname_0 = layer_part_values_pathname(next_sum, max_value)
        end
        if next_max_values.member?(max_value + 1)
          pathname_1 = layer_part_values_pathname(next_sum, max_value + 1)
        end
      end
      [pathname_0, pathname_1]
    end

    def solve_layer_part(sum, max_value)
      batches = make_layer_part_batches(sum, max_value)
      log_solve_layer(sum, max_value, batches.size)
      GC.start
      Parallel.each(batches) do |index, offset, previous, batch_size|
        states_pathname = layer_part_pathname(sum, max_value)
        values_pathname = layer_fragment_values_pathname(sum, max_value, index)
        policy_pathname = layer_fragment_policy_pathname(sum, max_value, index)
        vbyte_reader = VByteReader.new(states_pathname, offset, previous,
          batch_size)
        @solver.solve(
          vbyte_reader, sum, max_value, values_pathname, policy_pathname
        )
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
    end

    def find_layer_fragments(sum, max_value, klass)
      files = klass.glob(values_folder) do |name|
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

    def find_max_layer_sum
      LayerPartName.glob(layer_folder).map(&:sum).max
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
