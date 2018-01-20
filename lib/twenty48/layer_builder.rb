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

    def initialize(layer_model, batch_size, verbose: false)
      @layer_model = layer_model
      @batch_size = batch_size
      @valuer = layer_model.create_native_valuer
      @verbose = verbose

      # Otherwise we cannot concatenate the policy files as binary files.
      raise 'batch size must be multiple of 4' unless batch_size % 4 == 0
    end

    attr_reader :batch_size
    attr_reader :layer_model
    attr_reader :builder
    attr_reader :valuer

    def board_size
      layer_model.board_size
    end

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
        layer_start_states =
          start_states.select { |state| state.sum == layer_sum }.sort

        layer_start_states_by_max_value =
          layer_start_states.group_by(&:max_value)
        layer_start_states_by_max_value.each do |max_value, states|
          if layer_sum == 4
            # The sum 4 layer is complete.
            new_part(layer_sum, max_value).states_vbyte.write_states(states)
            write_layer_part_info(layer_sum, max_value, num_states: states.size)
          else
            # The sum 6 and 8 layers are reachable from the 4 layer, so we
            # need to output fragments for them.
            new_part(layer_sum, max_value).fragment_vbyte.new(
              input_sum: layer_sum,
              input_max_value: max_value,
              batch: 0
            ).write_states(states)
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

    #
    # If we have to restart a build from layer N, we need to turn layer N+2
    # back into fragments, so that we can merge the +2 successors of N into it
    # and also generate the +4 successors.
    #
    def prepare_to_restart_from(layer_sum)
      to_fragment = LayerPartName.glob(layer_folder).select do |name|
        name.sum > layer_sum
      end

      to_fragment.each do |name|
        new_name = LayerFragmentName.new(
          input_sum: name.sum,
          input_max_value: name.max_value,
          output_sum: name.sum,
          output_max_value: name.max_value,
          batch: 0
        )

        FileUtils.mv name.in(layer_folder), new_name.in(layer_folder)
        FileUtils.rm layer_part_info_pathname(name.sum, name.max_value)
      end
    end

    def build_layer(layer_sum)
      max_values = find_max_values(layer_sum)
      num_states = max_values.map do |max_value|
        build_layer_part(layer_sum, max_value)
        reduce_layer_parts(layer_sum, max_value)
        count_states(layer_sum, max_value)
      end.inject(:+)
      reduce_layer_parts(layer_sum, max_values.max + 1)
      num_states
    end

    def build_layer_part(sum, max_value)
      batches = make_layer_part_batches(sum, max_value)

      log_build_layer(sum, max_value, batches.size)

      return if batches.empty?

      build_layer_part_batches(sum, max_value, batches)
    end

    #
    # The build process can leave some empty files, and it's easiest to just
    # clean them up at the end.
    #
    def remove_empty_layer_parts(max_layer_sum)
      layer_model.part.each do |part|
        next if part.sum > max_layer_sum
        next if file_size(part.states_vbyte.to_s) > 0
        part.destroy!
      end
    end

    #
    # Find the maximum number of files we can open. This limit can be a problem
    # when merging large parts. Note that we assume that this does not change
    # over the lifetime of the process.
    #
    def max_files
      grace = 16
      @ulimit ||= `bash -c 'ulimit -n'`
      @ulimit.chomp.to_i - grace
    end

    private

    def write_layer_part_info(layer_sum, max_value, num_states:, index: [])
      pathname = new_part(layer_sum, max_value).info_json.to_s
      File.open(pathname, 'w') do |info_file|
        JSON.dump({
          num_states: num_states,
          batch_size: batch_size,
          index: index.to_a
        }, info_file)
      end
    end

    def layer_fragment_pathname(sum, max_value, step, jump, batch)
      new_part(sum + 2 * step, max_value + jump).fragment_vbyte.new(
        input_sum: sum,
        input_max_value: max_value,
        batch: batch
      ).mkdir!.to_s
    end

    def build_layer_part_batches(sum, max_value, batches)
      GC.start
      Parallel.each(batches) do |index, offset, previous, batch_size|
        run_native_layer_builder(
          sum, max_value, index, offset, previous, batch_size
        )
        STDOUT.write('.') if @verbose
        GC.start
      end
      puts if @verbose # put a line break after the dots from the parts
    end

    def create_native_layer_builder(sum, max_value, index, valuer)
      NativeLayerBuilder.create(
        board_size, max_value,
        layer_fragment_pathname(sum, max_value, 1, 0, index),
        layer_fragment_pathname(sum, max_value, 1, 1, index),
        layer_fragment_pathname(sum, max_value, 2, 0, index),
        layer_fragment_pathname(sum, max_value, 2, 1, index),
        valuer
      )
    end

    def run_native_layer_builder(sum, max_value, index, offset, previous,
      batch_size)
      input_pathname = new_part(sum, max_value).states_vbyte.to_s
      vbyte_reader = VByteReader.new(input_pathname, offset, previous,
        batch_size)
      builder = create_native_layer_builder(sum, max_value, index, valuer)
      builder.expand_all(vbyte_reader)
    end

    def reduce_layer_parts(sum, max_value)
      # The max_values are processed in ascending order, so once we've built
      # successors from a part, all parts with layer_sum = this layer_sum + 2
      # and max_value <= this max_value are done --- no other parts will add
      # successors to them.
      layer_model.part.where(sum: sum + 2).each do |output_part|
        next unless output_part.max_value <= max_value
        reduce_output_part_fragments(
          output_part,
          output_part.fragment_vbyte.to_a
        )
      end

      # fragments = LayerFragmentName.glob(layer_folder).select do |name|
      #   name.output_sum == sum + 2 && name.output_max_value <= max_value
      # end
      #
      # fragments_by_output_part = fragments.group_by do |name|
      #   LayerPartName.new(
      #     sum: name.output_sum,
      #     max_value: name.output_max_value
      #   )
      # end
      #
      # fragments_by_output_part.each do |output_name, input_names|
      #   reduce_output_part_fragments(output_name, input_names)
      # end
    end

    def reduce_output_part_fragments(output_name, input_names)
      # We may run out of file descriptors when we try to merge a lot of files.
      raise "too many batches: #{input_names.size}" if
        input_names.size > max_files
      input_pathnames = input_names.map(&:to_s)
      return if input_pathnames.empty?
      log_reduce_step(output_name.sum, output_name.max_value, input_pathnames)

      output_pathname = output_name.states_vbyte.to_s
      raise "already done: #{output_pathname}" if File.exist?(output_pathname)

      num_states, vbyte_index = merge_files(input_pathnames, output_pathname)
      write_layer_part_info(output_name.sum, output_name.max_value,
        num_states: num_states, index: vbyte_index)

      FileUtils.rm input_pathnames
    end

    def merge_files(input_files, output_file)
      vbyte_index = VByteIndex.new
      num_states = Twenty48.merge_states(StringVector.new(input_files),
        output_file, batch_size, vbyte_index)
      [num_states, vbyte_index]
    end

    def log_build_layer(layer_sum, max_value, num_batches)
      log format('build %d-%x: %d states (%d batches)',
        layer_sum, max_value, count_states(layer_sum, max_value), num_batches)
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
