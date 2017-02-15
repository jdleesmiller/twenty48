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
  # value layers, there is an option to discard them.
  #
  # In order to test the solver on intermediate layers, the `end_layer_sum` and
  # `end_value` parameters let you truncate the solve at a particular layer.
  # The resulting policy is junk, but it does at least let us test the
  # mechanisms before the build has completed.
  #
  class LayerSolver
    include Layers

    def initialize(board_size, layer_folder, values_folder, valuer,
      end_layer_sum: nil, end_value: Float::NAN,
      keep_value_layers: true, verbose: false)
      @layer_folder = layer_folder
      @values_folder = values_folder
      @end_layer_sum = end_layer_sum || find_layer_sums.max
      @solver = NativeLayerSolver.create(board_size, valuer, @end_layer_sum,
        end_value)
      @keep_value_layers = keep_value_layers
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
        prepare_lower_layer(layer_sum)
        layer_sum -= 2
      end
    end

    # TODO: this is where we break up into batches
    # no particular reason not to use the number of processors as the number
    # of batches --- no upper limit on batch size
    def solve_layer(layer_sum)
      # The states file can be missing if it's empty.
      states_pathname = layer_pathname(layer_sum)
      return unless File.exist?(states_pathname)

      values_pathname = layer_values_pathname(layer_sum)
      policy_pathname = layer_policy_pathname(layer_sum)
      vbyte_reader = VByteReader.new(states_pathname)
      @solver.solve(vbyte_reader, values_pathname, policy_pathname)
      vbyte_reader = nil
    end

    def prepare_lower_layer(layer_sum)
      states_pathname = layer_pathname(layer_sum)
      values_pathname = layer_values_pathname(layer_sum)

      if File.exist?(states_pathname) || File.exist?(values_pathname)
        @solver.prepare_lower_layer(states_pathname, values_pathname)
      else
        # If there are no states in a layer, we won't have any values or a
        # policy, either, so skip the layer.
        @solver.prepare_lower_layer(nil, nil)
      end
    end
  end
end
