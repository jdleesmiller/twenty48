# frozen_string_literal: true

require 'tmpdir'

module Twenty48
  #
  # Common methods for the native LayerBuilder class.
  #
  module NativeLayerBuilder
    def self.create(board_size, data_path, resolver)
      klass = case board_size
              when 2 then LayerBuilder2
              when 3 then LayerBuilder3
              when 4 then LayerBuilder4
              else raise "bad layer builder board_size: #{board_size}"
              end
      klass.new(data_path, resolver)
    end

    def build(max_states)
      build_start_state_layers

      skips = 0
      sum = 2
      while skips < 2
        sum += 2

        layer_pathname = make_layer_pathname(sum)
        unless File.exist?(layer_pathname)
          skips += 1
          next
        end

        skips = 0

        yield layer_pathname, File.stat(layer_pathname).size / 8 if block_given?

        build_layer(sum, 1, max_states)
        build_layer(sum, 2, max_states)
      end
      sum - skips * 2
    end

    RECORD_SIZE = 8

    def self.sort_layer(input_file)
      input_size = File.stat(input_file).size
      raise "bad input size: #{input_file}" unless input_size % RECORD_SIZE == 0

      # If the bytes are stored little-endian, the order of the bytes is
      # reversed, but the order of the nybbles within each byte is correct.
      sort_keys = (1..8).to_a.reverse.map do |c|
        "-k1.#{2 * c - 1},1.#{2 * c}"
      end.join(' ')

      Dir.mktmpdir do |tmp|
        output_file = File.join(tmp, 'output.bin')
        system <<-CMD
        cat #{input_file} \
            | xxd -cols #{RECORD_SIZE} -plain \
            | sort #{sort_keys} \
            | xxd -cols #{RECORD_SIZE} -plain -revert \
            > #{output_file}
        CMD
        output_size = File.stat(output_file).size

        raise "size mismatch: #{input_size} != #{output_size}" \
          if input_size != output_size

        FileUtils.mv output_file, input_file
      end
    end

    def layer_sums
      layer_files = Dir.glob(File.join(get_states_path, '*.bin'))
      layer_files.map { |pathname| File.basename(pathname, '.bin').to_i }
    end

    def sort_all_layers
      layer_sums.each do |sum|
        layer_pathname = make_layer_pathname(sum)
        yield layer_pathname if block_given?
        NativeLayerBuilder.sort_layer layer_pathname
      end
    end

    def states_by_layer(max_states)
      Hash[layer_sums.map do |sum|
        state_set = NativeStateHashSet.create(board_size, max_states)
        state_set.load_binary(make_layer_pathname(sum))
        [sum, state_set.to_a]
      end]
    end
  end

  #
  # Layered statespace builder for 2x2 boards.
  #
  class LayerBuilder2
    include NativeLayerBuilder

    def board_size
      2
    end
  end

  #
  # Layered statespace builder for 3x3 boards.
  #
  class LayerBuilder3
    include NativeLayerBuilder

    def board_size
      3
    end
  end

  #
  # Layered statespace builder for 4x4 boards.
  #
  class LayerBuilder4
    include NativeLayerBuilder

    def board_size
      4
    end
  end
end
