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

        puts "Solving layer #{layer_sum}" if @verbose
        solve_layer(layer_sum)
        layer_sum -= 2
      end
    end

    # TODO: this is where we break up into batches
    # no particular reason not to use the number of processors as the number
    # of batches --- no upper limit on batch size
    def solve_layer(sum)
      find_max_values(sum).each do |max_value|
        load_values(sum, max_value)
        solve_layer_part(sum, max_value)
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
      states_pathname = layer_part_pathname(sum, max_value)
      values_pathname = layer_part_values_pathname(sum, max_value)
      policy_pathname = layer_part_policy_pathname(sum, max_value)
      vbyte_reader = VByteReader.new(states_pathname)
      @solver.solve(
        vbyte_reader, sum, max_value, values_pathname, policy_pathname
      )
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
  end
end
