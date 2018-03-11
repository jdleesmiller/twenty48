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

            #
            # Fragment of a part generated during a solve.
            #
            class Fragment
              def remove_if_empty
                Dir.rmdir(to_s)
              rescue SystemCallError
                nil # Ignore --- directory not empty.
              end
            end

            #
            # Select a subset of states with at least a given probability.
            #
            class Tranche
              def solution
                parent
              end

              def part
                solution.parent
              end

              def board_size
                part.parent.board_size
              end

              def each_state_vbyte_unfiltered(&block)
                states_pathname = part.states_vbyte.to_s
                Twenty48.each_state_vbyte(board_size, states_pathname, &block)
              end

              def each_state_vbyte
                return unless bit_set.exist?
                bit_set_reader = BitSetReader.new(bit_set.to_s)
                each_state_vbyte_unfiltered do |state|
                  yield state if bit_set_reader.read
                end
              end

              def read_state_action_value
                return [] unless bit_set.exist?
                StateActionValue.subset(
                  bit_set.to_s,
                  part.states_vbyte.to_s,
                  solution.policy.to_s,
                  if solution.alternate_actions.exist?
                    solution.alternate_actions.to_s
                  end,
                  solution.values.exist? ? solution.values.to_s : nil
                )
              end

              #
              # Transient probabilities over a certain threshold.
              #
              class TransientPr
                def part
                  parent.part
                end

                def board_size
                  parent.board_size
                end

                def each_state_vbyte_unfiltered(&block)
                  parent.each_state_vbyte_unfiltered(&block)
                end

                def each_state_vbyte(&block)
                  parent.each_state_vbyte(&block)
                end

                def each_state_with_pr
                  return unless exist?
                  File.open(to_s, 'rb') do |file|
                    each_state_vbyte do |state|
                      yield(state, file.read(8).unpack('D')[0])
                    end
                  end
                end
              end

              #
              # Unpack a binary state-probability map.
              #
              module ReadStateProbabilityMap
                def each_state_with_pr
                  return unless exist?
                  File.open(to_s, 'rb') do |file|
                    until file.eof?
                      nybbles, pr = file.read(16).unpack('QD')
                      state = NativeState.create_from_nybbles(
                        parent.board_size, nybbles
                      )
                      yield state, pr
                    end
                  end
                end

                def read
                  results = []
                  each_state_with_pr do |state, pr|
                    results << [state, pr]
                  end
                  results
                end
              end

              #
              # Transient states and their probabilities.
              #
              class Transient
                include ReadStateProbabilityMap
              end

              class OutputFragment
                def board_size
                  parent.board_size
                end

                #
                # Transient states and their probabilities.
                #
                class Transient
                  include ReadStateProbabilityMap
                end

                class Losses
                  include ReadStateProbabilityMap
                end

                class Wins
                  include ReadStateProbabilityMap
                end
              end

              #
              # Win states and their absorbing probabilities.
              #
              class Wins
                include ReadStateProbabilityMap
              end

              #
              # Lose states and their absorbing probabilities.
              #
              class Losses
                include ReadStateProbabilityMap
              end
            end
          end

          def tranche(solution_attributes, tranche_attributes)
            target_solution = solution.find_by(solution_attributes)
            return unless target_solution
            target_solution.tranche.find_by(tranche_attributes)
          end

          def each_tranche_transient_pr(*args)
            target_tranche = tranche(*args)
            return if target_tranche.nil?
            target_tranche.transient_pr.each_state_with_pr do |state, pr|
              yield state, pr
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

        TrancheSummary = Struct.new(:sum, :max_value, :num_states, :total_pr)

        def each_tranche_state_action_value(
          solution_attributes, tranche_attributes
        )
          part.each do |part|
            part_solution = part.solution.find_by(solution_attributes)
            next unless part_solution
            part_tranche = part_solution.tranche.find_by(tranche_attributes)
            next unless part_tranche
            part_tranche.read_state_action_value.each do |state_action_value|
              yield state_action_value
            end
          end
        end

        def read_tranche_state_action_values(*args)
          state_action_values = []
          each_tranche_state_action_value(*args) do |state_action_value|
            state_action_values << state_action_value
          end
          state_action_values
        end

        def each_tranche_transient_pr(*args)
          part.each do |part|
            part.each_tranche_transient_pr(*args) do |state, pr|
              yield(state, pr)
            end
          end
        end

        def summarize_tranche_transient_pr(*args)
          part.map do |part|
            summary = TrancheSummary.new(part.sum, part.max_value, 0, 0.0)
            part.each_tranche_transient_pr(*args) do |_state, pr|
              summary.num_states += 1
              summary.total_pr += pr
            end
            summary if summary.num_states > 0
          end.compact
        end

        def summarize_tranche_wins(*args)
          part.map do |part|
            summary = TrancheSummary.new(part.sum, part.max_value, 0, 0.0)
            tranche = part.tranche(*args)
            next if tranche.nil?
            # rubocop:disable Performance/HashEachMethods (spurious)
            tranche.wins.read.each do |_state, pr|
              summary.num_states += 1
              summary.total_pr += pr
            end
            # rubocop:enable Performance/HashEachMethods
            summary if summary.num_states > 0
          end.compact
        end

        def summarize_tranche_losses(*args)
          part.map do |part|
            summary = TrancheSummary.new(part.sum, part.max_value, 0, 0.0)
            tranche = part.tranche(*args)
            next if tranche.nil?
            # rubocop:disable Performance/HashEachMethods (spurious)
            tranche.losses.read.each do |_state, pr|
              summary.num_states += 1
              summary.total_pr += pr
            end
            # rubocop:enable Performance/HashEachMethods
            summary if summary.num_states > 0
          end.compact
        end

        TrancheCsvSummary = Struct.new(
          :sum, :max_value, :kind, :log2, :num_states, :total_pr
        )

        def summarize_tranche_csvs(*args)
          results = []
          part.each do |part|
            tranche = part.tranche(*args)
            next if tranche.nil?
            results += read_tranche_csv(part, tranche.transient_csv, :transient)
            results += read_tranche_csv(part, tranche.wins_csv, :win)
            results += read_tranche_csv(part, tranche.losses_csv, :loss)
          end
          results
        end

        def read_tranche_csv(part, file, kind)
          return [] unless file.exist?
          csv_options = {
            headers: true,
            converters: :numeric,
            header_converters: :symbol
          }
          results = []
          CSV.foreach(file.to_s, csv_options) do |row|
            results << TrancheCsvSummary.new(
              part.sum, part.max_value, kind,
              row[:log2], row[:num_states], row[:total_pr]
            )
          end
          results
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

    def check_batch_size_for_alternate_actions(batch_size)
      return if alternate_action_tolerance < 0
      # Otherwise we cannot concatenate the alternate actions as binary files.
      raise 'batch size must be multiple of 16' unless batch_size % 16 == 0
    end

    def check_batch_size_for_bit_set(batch_size)
      # Otherwise we cannot concatenate bit sets as binary files.
      raise 'batch size must be multiple of 8' unless batch_size % 8 == 0
    end

    def concatenate(input_pathnames, output_pathname)
      return if input_pathnames.empty?

      first_pathname = input_pathnames.shift
      FileUtils.mv first_pathname, output_pathname

      input_pathnames.each do |input_pathname|
        system %(cat "#{input_pathname}" >> "#{output_pathname}")
        FileUtils.rm input_pathname
      end
    end

    def log(message)
      return unless @verbose
      puts "#{Time.now}: #{message}"
    end
  end
end
