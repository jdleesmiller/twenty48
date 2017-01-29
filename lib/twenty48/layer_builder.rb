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
    def initialize(board_size, layer_folder, batch_size, valuer, verbose: false)
      @layer_folder = layer_folder
      @builder = NativeLayerBuilder.create(board_size, valuer)
      @batch_size = batch_size
      @verbose = verbose
    end

    attr_reader :batch_size
    attr_reader :layer_folder
    attr_reader :builder

    STATE_BYTE_SIZE = 8

    def board_size
      builder.board_size
    end

    #
    # How many successor states can we safely generate from a single batch if
    # we use all of the available cores?
    #
    def self.find_max_successor_states(working_memory)
      batch_memory = working_memory / Parallel.processor_count
      batch_memory / STATE_BYTE_SIZE
    end

    #
    # File name for a complete layer with the given sum.
    #
    def layer_basename(layer_sum)
      format('%04d.vbyte', layer_sum)
    end

    def layer_pathname(layer_sum, folder: layer_folder)
      File.join(folder, layer_basename(layer_sum))
    end

    def layer_info_basename(layer_sum)
      format('%04d.json', layer_sum)
    end

    def layer_info_pathname(layer_sum)
      File.join(layer_folder, layer_info_basename(layer_sum))
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
        Twenty48.write_states_vbyte(layer_start_states,
          layer_pathname(layer_sum))
        write_layer_info(layer_sum, num_states: layer_start_states.size)
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
      input_info = read_layer_info(layer_sum)
      num_input_states = input_info['num_states']
      num_batches = input_info['index'].size

      log_build_layer(layer_sum, num_input_states, num_batches)

      jobs = (0...num_batches).to_a.product((1..2).to_a)

      Dir.mktmpdir do |work_folder|
        GC.start
        batches = Parallel.map(jobs) do |batch_index, step|
          batch = Batch.new(
            builder, work_folder, layer_sum, input_layer_pathname, step,
            batch_index,
            input_info['index'][batch_index],
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
      layer_files = Dir.glob(File.join(layer_folder, '*.vbyte'))
      layer_files.map { |pathname| File.basename(pathname, '.vbyte').to_i }
    end

    def states_by_layer
      Hash[layer_sums.map do |layer_sum|
        states = Twenty48.read_states_vbyte(board_size,
          layer_pathname(layer_sum))
        [layer_sum, states]
      end]
    end

    def read_layer_info(layer_sum)
      info = JSON.parse(File.read(layer_info_pathname(layer_sum)))
      entries = info['index'].map do |entry|
        VByteIndexEntry.new(entry['byte_offset'], entry['previous'])
      end
      entries.unshift(VByteIndexEntry.new)
      info['index'] = VByteIndex.new(entries)
      info
    end

    def count_states(layer_sum)
      read_layer_info(layer_sum)['num_states']
    end

    private

    def write_layer_info(layer_sum, num_states:, index: [])
      File.open(layer_info_pathname(layer_sum), 'w') do |info_file|
        JSON.dump({
          num_states: num_states,
          batch_size: batch_size,
          index: index.to_a
        }, info_file)
      end
    end

    Batch = Struct.new(
      :builder,
      :work_folder,
      :input_layer_sum,
      :input_layer_pathname,
      :step,
      :batch_index,
      :index_entry,
      :batch_size,
      :verbose
    ) do
      def output_layer_sum
        input_layer_sum + 2 * step
      end

      def basename
        format('%04d-step-%d-index-%04d.vbyte',
          output_layer_sum, step, batch_index)
      end

      def output_pathname
        File.join(work_folder, basename)
      end

      def build
        vbyte_reader = VByteReader.new(input_layer_pathname,
          index_entry.byte_offset, index_entry.previous, batch_size)
        builder.build_layer(vbyte_reader, output_pathname, step)
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
        merge_results(output_sum, work_folder, work_layer, input_pathnames)
      end
    end

    def batch_pathnames_for_step(batches, step)
      batches.map do |batch_step, pathname|
        pathname if batch_step == step
      end.compact
    end

    def merge_results(output_sum, work_folder, work_layer, input_pathnames)
      num_work_states, work_index = merge_files(input_pathnames, work_layer)
      output_pathname = layer_pathname(output_sum)
      if File.exist?(output_pathname)
        temp_pathname = File.join(work_folder, 'new_layer.vbyte')
        num_states, vbyte_index = merge_files([work_layer, output_pathname],
          temp_pathname)
        write_layer_info(output_sum,
          num_states: num_states, index: vbyte_index)
        FileUtils.mv temp_pathname, output_pathname
      else
        write_layer_info(output_sum,
          num_states: num_work_states, index: work_index)
        FileUtils.mv work_layer, output_pathname
      end
    end

    def merge_files(input_files, output_file)
      vbyte_index = VByteIndex.new
      num_states = builder.merge_files(StringVector.new(input_files),
        output_file, batch_size, vbyte_index)
      [num_states, vbyte_index]
    end

    def file_size(pathname)
      File.stat(pathname).size
    end

    def count_states_if_any(layer_sum)
      count_states(layer_sum)
    rescue Errno::ENOENT
      0
    end

    def remove_empty_layers(max_layer_sum)
      # The build process can leave some empty files, and it's easiest to just
      # clean them up at the end.
      layer_sum = 4
      while layer_sum <= max_layer_sum
        remove_empty_layer(layer_sum) if count_states_if_any(layer_sum) == 0
        layer_sum += 2
      end
    end

    def remove_empty_layer(layer_sum)
      pathname = layer_pathname(layer_sum)
      if File.exist?(pathname)
        raise "nonempty layer: #{layer_sum}" if file_size(pathname) > 0
        FileUtils.rm pathname
      end
      FileUtils.rm_f layer_info_pathname(layer_sum)
    end

    def log(message)
      return unless @verbose
      puts "#{Time.now}: #{message}"
    end

    def log_build_layer(layer_sum, num_input_states, num_batches)
      log format('build %d: %d states (%d batches)',
        layer_sum, num_input_states, num_batches)
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
