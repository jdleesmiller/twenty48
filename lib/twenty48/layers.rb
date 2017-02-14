# frozen_string_literal: true

require 'parallel'
require 'tmpdir'

module Twenty48
  #
  # Handling for layer files.
  #
  module Layers
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

    def layer_values_basename(layer_sum)
      format('%04d.values', layer_sum)
    end

    def layer_values_pathname(layer_sum, folder: values_folder)
      File.join(folder, layer_values_basename(layer_sum))
    end

    def layer_policy_basename(layer_sum)
      format('%04d.policy', layer_sum)
    end

    def layer_policy_pathname(layer_sum, folder: values_folder)
      File.join(folder, layer_policy_basename(layer_sum))
    end

    def find_layers(folder: layer_folder)
      Dir.glob(File.join(folder, '????.vbyte'))
    end

    def find_layer_sums(folder: layer_folder)
      find_layers(folder: folder).map { |f| File.basename(f, '.vbyte').to_i }
    end
  end
end
