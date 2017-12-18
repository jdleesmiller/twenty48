# frozen_string_literal: true

module Twenty48
  #
  # Once we've solved a layered model, thin out the states so that we only visit
  # those states that we can encounter while playing with the optimal policy.
  #
  class LayerCompactor < LayerBuilder
    def initialize(board_size, original_layer_folder, batch_size, valuer,
      original_policy_folder, compacted_layer_folder, verbose: false)
      super(board_size, compacted_layer_folder, batch_size, valuer,
        verbose: verbose)
      @original_policy_folder = original_policy_folder
      @original_layer_folder = original_layer_folder
    end

    attr_reader :original_policy_folder
    attr_reader :original_layer_folder

    #
    # Hook into the start state generation and the reduce step to copy over the
    # the used subset of the policy once we've finished each layer.
    #
    def write_layer_part_info(layer_sum, max_value, num_states:, index: [])
      super

      layer_part_name = LayerPartName.new(
        sum: layer_sum,
        max_value: max_value
      )
      policy_name = LayerPartPolicyName.new(
        sum: layer_sum,
        max_value: max_value
      )

      original_input_pathname = layer_part_name.in(original_layer_folder)
      original_vbyte_reader = VByteReader.new(original_input_pathname)
      original_policy_pathname = policy_name.in(original_policy_folder)
      original_policy_reader = PolicyReader.new(original_policy_pathname)

      subset_input_pathname = layer_part_name.in(layer_folder)
      subset_vbyte_reader = VByteReader.new(subset_input_pathname)
      subset_policy_pathname = policy_name.in(layer_folder)
      subset_policy_writer = PolicyWriter.new(subset_policy_pathname)

      Twenty48.subset_policy(
        original_vbyte_reader,
        original_policy_reader,
        subset_vbyte_reader,
        subset_policy_writer
      )
    end

    #
    # Hook into the layer build step to call expand_with_policy.
    #
    def run_native_layer_builder(sum, max_value, index, offset, previous,
      batch_size)
      layer_part_name = LayerPartName.new(
        sum: sum,
        max_value: max_value
      )
      vbyte_reader = VByteReader.new(
        layer_part_name.in(layer_folder), offset, previous, batch_size
      )

      policy_name = LayerPartPolicyName.new(
        sum: sum,
        max_value: max_value
      )
      policy_reader = PolicyReader.new(policy_name.in(layer_folder))
      policy_reader.skip(index * batch_size)

      builder = create_native_layer_builder(sum, max_value, index, valuer)
      builder.expand_with_policy(vbyte_reader, policy_reader)
    end

    #
    # Also clean up policy files for empty layers.
    #
    def remove_layer_part(name)
      super
      FileUtils.rm_f LayerPartPolicyName.new(
        sum: name.sum, max_value: name.max_value
      ).in(layer_folder)
    end
  end
end
