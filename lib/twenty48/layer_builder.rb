# frozen_string_literal: true

require 'parallel'
require 'tmpdir'

module Twenty48
  #
  # A layer builder that builds each individual layer using map-reduce.
  #
  # So... do we need /tmp, or should we instead just use the layer directory
  # but write a 'move to cold storage' script? Keeping it all in one place
  # would avoid some cross-device copying from tmp to other device for the
  # step-4 merge.
  #
  # If we do keep it all in the layer directory... when should we merge? It
  # seems like we could just keep the part files there and then, once we have
  # generated all successors to layer n, do the merges for all n+2 layers,
  # since we know that we'll be finished with them. The n+4 layers would still
  # be around, but their file names wouldn't conflict. Then, optionally, bzip2
  # and ship layer n to cold storage.
  #
  class LayerBuilder
    include Layers

    def initialize(board_size, layer_folder, max_output_states, valuer,
      verbose: false)
      @board_size = board_size
      @layer_folder = layer_folder
      @max_output_states = max_output_states
      @valuer = valuer
      @verbose = verbose
    end

    attr_reader :board_size
    attr_reader :layer_folder
    attr_reader :max_output_states
    attr_reader :builder
    attr_reader :valuer

    STATE_BYTE_SIZE = 8

    #
    # How many successor states can we safely generate from a single batch if
    # we use all of the available cores?
    #
    def self.find_max_successor_states(working_memory)
      batch_memory = working_memory / Parallel.processor_count
      batch_memory / STATE_BYTE_SIZE
    end

    #
    # Build the first 3 layers, which have sums 4, 6, and 8. The layer with sum
    # 4 is complete, so we just leave it in .bin form. The later layers we keep
    # in hex form for merging with the successors of the layer with sum 4.
    #
    def build_start_state_layers
      start_states = Twenty48.generate_start_states(board_size: board_size)

      layer_sum = 4
      while layer_sum <= 8
        layer_start_states = start_states.select do |state|
          state.sum == layer_sum
        end.sort

        layer_start_states_by_max_value =
          layer_start_states.group_by(&:max_value)
        layer_start_states_by_max_value.each do |max_value, states|
          if layer_sum == 4
            # The sum 4 layer is complete.
            Twenty48.write_states_vbyte(states,
              layer_part_pathname(layer_sum, max_value))
            write_layer_part_info(layer_sum, max_value, num_states: states.size)
          else
            # The sum 6 and 8 layers are reachable from the 4 layer, so we
            # need to output fragments for them.
            fragment_pathname = LayerFragmentName.new(
              input_sum: layer_sum,
              input_max_value: max_value,
              output_sum: layer_sum,
              output_max_value: max_value,
              remainder: 0,
              fragment: 0
            ).in(layer_folder)
            Twenty48.write_states_vbyte(states, fragment_pathname)
          end
        end
        layer_sum += 2
      end
    end

    #
    # Starting with the output from `build_start_state_layers`, build each
    # subsequent layer.
    #
    def build(start_layer_sum: 4)
      skips = 0
      layer_sum = start_layer_sum
      while skips < 2
        num_states = build_layer(layer_sum)
        if num_states > 0
          skips = 0
        else
          skips += 1
        end
        layer_sum += 2
      end
      remove_empty_layer_parts(layer_sum + 4)
      nil
    end

    def build_layer(layer_sum)
      max_values = find_max_values(layer_sum)
      num_states = max_values.map do |max_value|
        log_build_layer(layer_sum, max_value)
        build_layer_part(layer_sum, max_value)
        reduce_layer_parts(layer_sum, max_value)
        count_states(layer_sum, max_value)
      end.inject(:+)
      reduce_layer_parts(layer_sum, max_values.max + 1)
      num_states
    end

    def build_layer_part(sum, max_value)
      return if count_states(sum, max_value) == 0
      divisor = Parallel.processor_count
      remainders = 0...divisor
      GC.start
      Parallel.each(remainders) do |remainder|
        builder = NativeLayerBuilder.create(
          board_size, layer_part_pathname(sum, max_value), max_value, valuer
        )
        fragment = 0
        loop do
          done = builder.build_layer(remainder, divisor, max_output_states)
          builder.write_outputs(
            layer_fragment_pathname(sum, max_value, 1, 0, remainder, fragment),
            layer_fragment_pathname(sum, max_value, 1, 1, remainder, fragment),
            layer_fragment_pathname(sum, max_value, 2, 0, remainder, fragment),
            layer_fragment_pathname(sum, max_value, 2, 1, remainder, fragment)
          )
          fragment += 1
          STDOUT.write('.') if @verbose
          break if done
        end
        GC.start
      end
      puts if @verbose # put a line break after the dots from the parts
    end

    def count_states(sum, max_value)
      read_layer_part_info(sum, max_value)['num_states']
    end

    #
    # The build process can leave some empty files, and it's easiest to just
    # clean them up at the end.
    #
    def remove_empty_layer_parts(max_layer_sum)
      to_remove = LayerPartName.glob(layer_folder).select do |name|
        name.sum <= max_layer_sum && file_size(name.in(layer_folder)) == 0
      end

      to_remove.each do |name|
        FileUtils.rm name.in(layer_folder)
        FileUtils.rm_f LayerPartInfoName.new(
          sum: name.sum, max_value: name.max_value
        ).in(layer_folder)
      end
    end

    private

    def read_layer_part_info(sum, max_value)
      JSON.parse(File.read(layer_part_info_pathname(sum, max_value)))
    end

    def write_layer_part_info(layer_sum, max_value, num_states:)
      pathname = layer_part_info_pathname(layer_sum, max_value)
      File.open(pathname, 'w') do |info_file|
        JSON.dump({ num_states: num_states }, info_file)
      end
    end

    def layer_fragment_pathname(sum, max_value, step, jump, remainder, fragment)
      LayerFragmentName.new(
        input_sum: sum,
        input_max_value: max_value,
        output_sum: sum + 2 * step,
        output_max_value: max_value + jump,
        remainder: remainder,
        fragment: fragment
      ).in(layer_folder)
    end

    def reduce_layer_parts(sum, max_value)
      # The max_values are processed in ascending order, so once we've built
      # successors from a part, all parts with layer_sum = this layer_sum + 2
      # and max_value <= this max_value are done --- no other parts will add
      # successors to them.
      fragments = LayerFragmentName.glob(layer_folder).select do |name|
        name.output_sum == sum + 2 && name.output_max_value <= max_value
      end

      fragments_by_output_part = fragments.group_by do |name|
        LayerPartName.new(
          sum: name.output_sum,
          max_value: name.output_max_value
        )
      end

      fragments_by_output_part.each do |output_name, input_names|
        # Can't currently handle too many; we may run out of file descriptors
        # when we try to merge.
        raise "too many batches: #{input_names.size}" if input_names.size > 1000
        input_pathnames = input_names.map { |name| name.in(layer_folder) }
        log_reduce_step(output_name.sum, output_name.max_value, input_pathnames)

        output_pathname = output_name.in(layer_folder)
        raise "already done: #{output_pathname}" if File.exist?(output_pathname)

        num_states = merge_files(input_pathnames, output_pathname)
        write_layer_part_info(output_name.sum, output_name.max_value,
          num_states: num_states)

        FileUtils.rm input_pathnames
      end
    end

    def merge_files(input_files, output_file)
      Twenty48.merge_states(StringVector.new(input_files), output_file)
    end

    def file_size(pathname)
      File.stat(pathname).size
    end

    def log(message)
      return unless @verbose
      puts "#{Time.now}: #{message}"
    end

    def log_build_layer(layer_sum, max_value)
      log format('build %d-%x: %d states',
        layer_sum, max_value, count_states(layer_sum, max_value))
    end

    def log_reduce_step(sum, max_value, input_pathnames)
      sizes = input_pathnames.map { |pathname| file_size(pathname) }
      total_size = sizes.inject(&:+)
      max_size = sizes.max
      log format(
        'reduce %d-%d: %.1fMiB (%.1fMiB max)', sum, max_value,
        total_size.to_f / 1024**2, max_size.to_f / 1024**2
      )
    end
  end
end
