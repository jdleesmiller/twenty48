# frozen_string_literal: true

require 'parallel'

module Twenty48
  class Data
    class Game
      #
      # Model with states organized into layers (and parts).
      #
      class LayerModel
        #
        # A set of states with the same tile sum and max value.
        #
        class Part
          #
          # Read and write states in vbyte format.
          #
          module VByteStateUtilities
            def board_size
              parent.parent.parent.board_size
            end

            def read_states
              Twenty48.read_states_vbyte(board_size, to_s)
            end

            def write_states(states)
              parent.mkdir!
              Twenty48.write_states_vbyte(states, to_s)
            end
          end

          #
          # States in order, vbyte-encoded.
          #
          class StatesVByte
            include VByteStateUtilities
          end

          #
          # A fragment of a part that is still being built.
          #
          class FragmentVByte
            include VByteStateUtilities
          end

          #
          # JSON file with size and index data for a layer part.
          #
          class InfoJson
            def read
              info = JSON.parse(File.read(to_s))
              entries = info['index'].map do |entry|
                VByteIndexEntry.from_raw(entry)
              end
              entries.unshift(VByteIndexEntry.new)
              info['index'] = VByteIndex.new(entries)
              info
            end
          end

          class Solution
            #
            # Value function
            #
            class Values
              def board_size
                parent.parent.parent.parent.board_size
              end

              def read_state_values
                pairs = []
                File.open(to_s, 'rb') do |f|
                  until f.eof?
                    nybbles, value = f.read(16).unpack('QD')
                    pairs << [
                      NativeState.create_from_nybbles(board_size, nybbles),
                      value
                    ]
                  end
                end
                pairs
              end
            end
          end
        end

        def board_size
          parent.board_size
        end

        def max_exponent
          parent.max_exponent
        end

        def create_native_valuer(discount: 1.0)
          NativeValuer.create(
            board_size: board_size,
            max_exponent: max_exponent,
            max_depth: max_depth,
            discount: discount # discount does not matter for build step
          )
        end
      end
    end
  end

  #
  # Handling for layer files.
  #
  module Layers
    def new_part(sum, max_value)
      layer_model.part.new(sum: sum, max_value: max_value)
    end

    def find_max_values(layer_sum)
      layer_model.part.where(sum: layer_sum).map(&:max_value)
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

    def layer_part_states_pathname(sum, max_value)
      new_part(sum, max_value).states_vbyte.to_s
    end

    def read_layer_part_info(sum, max_value)
      new_part(sum, max_value).info_json.read
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
