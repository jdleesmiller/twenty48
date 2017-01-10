# frozen_string_literal: true

require 'parallel'
require 'tmpdir'

module Twenty48
  #
  # A layer builder that builds each individual layer using map-reduce.
  #
  # The general flow is
  # ```
  # [layer_folder]/[sum].bin
  # -> tmp/[sum + 2]-1-[offset]-offset.bin
  #   -> tmp/[sum + 2].bin
  #   -> (merge with [layer_folder]/[sum + 2].bin if it exists)
  #   -> [layer_folder]/[sum + 2].bin
  # -> tmp/[sum + 4]-2-[offset]-offset.bin
  #   -> tmp/[sum + 4].bin
  #   -> (merge with [layer_folder]/[sum + 4].bin if it exists)
  #   -> [layer_folder]/[sum + 4].bin
  # ```
  #
  class LayerBuilder
    def initialize(board_size, layer_folder, max_batch_size, valuer,
      verbose: false)
      @layer_folder = layer_folder
      @builder = NativeLayerBuilder.create(board_size, valuer)
      @max_batch_size = max_batch_size
      @verbose = verbose
    end

    attr_reader :max_batch_size
    attr_reader :layer_folder
    attr_reader :builder

    STATE_BINARY_SIZE = 8

    def board_size
      builder.board_size
    end

    #
    # How many successor states can we safely generate from a single batch if
    # we use all of the available cores?
    #
    def self.find_max_successor_states(working_memory)
      batch_memory = working_memory / Parallel.processor_count
      batch_memory / STATE_BINARY_SIZE
    end

    #
    # File name for a complete layer with the given sum.
    #
    def layer_basename(layer_sum)
      format('%04d.bin', layer_sum)
    end

    def layer_pathname(layer_sum, folder: layer_folder)
      File.join(folder, layer_basename(layer_sum))
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
        Twenty48.write_states_bin(layer_start_states, layer_pathname(layer_sum))
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
      remove_empty_layers(layer_sum + 4)
      layer_sum - skips * 2
    end

    def build_layer(layer_sum)
      input_layer_pathname = layer_pathname(layer_sum)
      num_input_states = file_size(input_layer_pathname) / STATE_BINARY_SIZE
      num_batches, batch_size = find_num_batches(num_input_states)

      log_build_layer(layer_sum, num_input_states, num_batches, batch_size)

      jobs = (0..num_batches).to_a.product((1..2).to_a)

      Dir.mktmpdir do |work_folder|
        GC.start
        batches = Parallel.map(jobs) do |batch_index, step|
          batch = Batch.new(
            builder,
            work_folder,
            layer_sum,
            input_layer_pathname,
            batch_index,
            step,
            batch_size,
            @verbose
          )
          batch.build
          GC.start
          [step, batch.output_pathname]
        end
        reduce work_folder, layer_sum, batches
      end
      num_input_states
    end

    def layer_sums
      layer_files = Dir.glob(File.join(layer_folder, '*.bin'))
      layer_files.map { |pathname| File.basename(pathname, '.bin').to_i }
    end

    def states_by_layer(max_states)
      Hash[layer_sums.map do |layer_sum|
        state_set = NativeStateHashSet.create(board_size, max_states)
        state_set.load_binary(layer_pathname(layer_sum))
        [layer_sum, state_set.to_a]
      end]
    end

    private

    # Find the number of batches needed. If we don't have enough batches to keep
    # all of the CPUs busy, choose smaller batch sizes.
    def find_num_batches(num_input_states)
      min_batches = (Parallel.processor_count / 2.0).ceil
      num_batches = num_input_states / max_batch_size
      if num_batches < min_batches
        num_batches = min_batches
        batch_size = num_input_states / num_batches
      end
      batch_size = 1 if batch_size < 1
      [num_batches, batch_size]
    end

    Batch = Struct.new(
      :builder,
      :work_folder,
      :input_layer_sum,
      :input_layer_pathname,
      :batch_index,
      :step,
      :batch_size,
      :verbose
    ) do
      def output_layer_sum
        input_layer_sum + 2 * step
      end

      def offset
        batch_index * batch_size
      end

      def basename
        format('%04d-step-%d-offset-%012d.bin', output_layer_sum, step, offset)
      end

      def output_pathname
        File.join(work_folder, basename)
      end

      def build
        builder.build_layer(
          input_layer_pathname,
          output_pathname,
          step,
          offset,
          batch_size
        )
        STDOUT.write('.') if verbose
      end
    end

    def reduce(work_folder, input_layer_sum, batches)
      puts if @verbose # put a line break after the dots from the batches

      # If we have enough cores, it might make sense to run the sorts for both
      # steps in parallel. TBD.
      [1, 2].each do |step|
        input_pathnames = batch_pathnames_for_step(batches, step)
        log_reduce_step(input_layer_sum, step, input_pathnames)
        output_sum = input_layer_sum + 2 * step
        work_layer = layer_pathname(output_sum, folder: work_folder)
        merge_files(input_pathnames, work_layer)
        merge_results(output_sum, work_folder, work_layer)
      end
    end

    def batch_pathnames_for_step(batches, step)
      batches.map do |batch_step, pathname|
        pathname if batch_step == step
      end.compact
    end

    def merge_results(output_sum, work_folder, work_layer)
      output_pathname = layer_pathname(output_sum)
      if File.exist?(output_pathname)
        temp_pathname = File.join(work_folder, 'new_layer.bin')
        merge_files([work_layer, output_pathname], temp_pathname)
        FileUtils.mv temp_pathname, output_pathname
      else
        FileUtils.mv work_layer, output_pathname
      end
    end

    def merge_files(input_files, output_file)
      builder.merge_files(StringVector.new(input_files), output_file)
    end

    def file_size(pathname)
      File.stat(pathname).size
    end

    def remove_if_empty(pathname)
      FileUtils.rm pathname if file_size(pathname) == 0
    rescue Errno::ENOENT # rubocop:disable Lint/HandleExceptions
      # We were going to remove it anyway.
    end

    def remove_empty_layers(max_layer_sum)
      # The build process can leave some empty .bin and .hex files, and it's
      # easiest to just clean them up at the end.
      layer_sum = 4
      while layer_sum <= max_layer_sum
        remove_if_empty(layer_pathname(layer_sum))
        layer_sum += 2
      end
      remove_if_empty(layer_pathname(max_layer_sum))
    end

    def log(message)
      return unless @verbose
      puts "#{Time.now}: #{message}"
    end

    def log_build_layer(layer_sum, num_input_states, num_batches, batch_size)
      log format('build %d: %d states (%d batches of ~%d)',
        layer_sum, num_input_states, num_batches, batch_size)
    end

    def log_reduce_step(input_layer_sum, step, input_pathnames)
      sizes = input_pathnames.map { |pathname| file_size(pathname) }
      total_size = sizes.inject(&:+)
      max_size = sizes.max
      log format(
        'reduce %d (step %d): %.1fMiB (%.1fMiB max)',
        input_layer_sum, step,
        total_size.to_f / 1024**2, max_size.to_f / 1024**2
      )
    end
  end
end
