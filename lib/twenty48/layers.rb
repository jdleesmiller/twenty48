# frozen_string_literal: true

require 'parallel'
require 'key_value_name'

module Twenty48
  LayerPartName = KeyValueName.new do |n|
    n.key :sum, type: Numeric, format: '%04d'
    n.key :max_value, type: Numeric, format: '%x'
    n.extension :vbyte
  end

  #
  # Layer Part: A 'layer' has the same sum, and a 'layer part' has the same
  # sum and `max_value`.
  #
  class LayerPartName
    def read_states(board_size, folder:)
      Twenty48.read_states_vbyte(board_size, self.in(folder))
    end
  end

  LayerPartInfoName = KeyValueName.new do |n|
    n.include_keys LayerPartName
    n.extension :json
  end

  #
  # Layer Part Info: A JSON file with size and index data for a layer part.
  #
  class LayerPartInfoName
    def read(folder:)
      info = JSON.parse(File.read(self.in(folder)))
      entries = info['index'].map { |entry| VByteIndexEntry.from_raw(entry) }
      entries.unshift(VByteIndexEntry.new)
      info['index'] = VByteIndex.new(entries)
      info
    end
  end

  LayerPartValuesName = KeyValueName.new do |n|
    n.include_keys LayerPartName
    n.extension :values
  end

  #
  # A value function with fixed-size state / value pairs.
  #
  class LayerPartValuesName
    def read(board_size, folder:)
      pairs = []
      File.open(self.in(folder), 'rb') do |f|
        until f.eof?
          nybbles, value = f.read(16).unpack('QD')
          pairs << [NativeState.create_from_nybbles(board_size, nybbles), value]
        end
      end
      pairs
    end
  end

  LayerPartPolicyName = KeyValueName.new do |n|
    n.include_keys LayerPartName
    n.extension :policy
  end

  LayerFragmentName = KeyValueName.new do |n|
    n.key :input_sum, type: Numeric, format: '%04d'
    n.key :input_max_value, type: Numeric, format: '%x'
    n.key :output_sum, type: Numeric, format: '%04d'
    n.key :output_max_value, type: Numeric, format: '%x'
    n.key :batch, type: Numeric, format: '%04d'
    n.extension :vbyte
  end

  #
  # A fragment of a layer that is still being built.
  #
  class LayerFragmentName
    def read_states(board_size, folder:)
      Twenty48.read_states_vbyte(board_size, self.in(folder))
    end
  end

  LayerFragmentValuesName = KeyValueName.new do |n|
    n.include_keys LayerPartName
    n.key :batch, type: Numeric, format: '%04d'
    n.extension :values
  end

  LayerFragmentPolicyName = KeyValueName.new do |n|
    n.include_keys LayerPartName
    n.key :batch, type: Numeric, format: '%04d'
    n.extension :policy
  end

  #
  # Handling for layer files.
  #
  module Layers
    def layer_part_pathname(sum, max_value, folder: layer_folder)
      LayerPartName.new(sum: sum, max_value: max_value).in(folder)
    end

    def layer_part_info_pathname(sum, max_value, folder: layer_folder)
      LayerPartInfoName.new(sum: sum, max_value: max_value).in(folder)
    end

    def find_max_values(layer_sum, folder: layer_folder)
      LayerPartName.glob(folder)
        .map { |name| name.max_value if name.sum == layer_sum }
        .compact
        .sort
    end

    def make_layer_part_batches(sum, max_value)
      input_info = read_layer_part_info(sum, max_value)
      return [] if input_info['num_states'] == 0

      input_index = input_info['index']
      batch_size = input_info['batch_size']
      Array.new(input_index.size) do |i|
        [i, input_index[i].byte_offset, input_index[i].previous, batch_size]
      end
    rescue Errno::ENOENT
      []
    end

    def read_layer_part_info(sum, max_value)
      LayerPartInfoName.new(sum: sum, max_value: max_value)
        .read(folder: layer_folder)
    end

    def file_size(pathname)
      File.stat(pathname).size
    end

    def file_size_if_exists(pathname)
      file_size(pathname)
    rescue Errno::ENOENT
      0
    end

    def count_states(sum, max_value)
      read_layer_part_info(sum, max_value)['num_states']
    rescue Errno::ENOENT
      0
    end

    def log(message)
      return unless @verbose
      puts "#{Time.now}: #{message}"
    end
  end
end
