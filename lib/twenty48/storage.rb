# frozen_string_literal: true

require 'csv'
require 'json'

require 'key_value_name'

module Twenty48
  #
  # Utilities for reading and writing things from and to disk.
  #
  module Storage
    module_function

    def bunzip(pathname)
      IO.popen("bunzip2 < #{pathname}") { |input| yield(input) }
    end

    def read_bzipped_json(pathname)
      bunzip(pathname) { |input| JSON.parse(input.read) }
    end

    def read_bzipped_csv(pathname, options = { headers: :first_row })
      bunzip(pathname) { |input| yield(CSV(input, options)) }
    end

    def json_string_to_state(string)
      Twenty48::State.new(JSON.parse(string))
    end
  end

  Data = KeyValueName.schema do
    folder :game do
      key :board_size, type: Integer
      key :max_exponent, type: Integer, format: '%x'

      folder :model do
        key :resolver_strategy, type: Symbol
        key :max_resolve_depth, type: Integer, format: '%d'

        # Hash model
        file :hash, :json
        file :hash, :json, :bz2

        # Array model
        file :array, :bin
        file :array, :bin, :bz2

        # Solution (policy and values)
        folder :solution do
          key :discount, type: Float
          key :tolerance, type: Float
          key :solve_strategy, type: Symbol

          file :solution, :csv
          file :solution, :csv, :bz2

          file :graph, :dot
          file :graph, :dot, :bz2
        end
      end

      folder :layer_model do
        key :max_depth, type: Integer

        folder :part do
          key :sum, type: Integer, format: '%04d'
          key :max_value, type: Integer, format: '%x'

          file :fragment, :vbyte, class_name: :FragmentVByte do
            key :input_sum, type: Integer, format: '%04d'
            key :input_max_value, type: Integer, format: '%x'
            key :batch, type: Integer, format: '%04d'
          end

          file :info, :json
          file :states, :vbyte, class_name: :StatesVByte

          folder :solution do
            key :discount, type: Float
            key :method, type: Symbol
            key :alternate_action_tolerance, type: Float

            folder :fragment do
              key :batch, type: Integer, format: '%04d'

              file :values
              file :policy
              file :alternate_actions

              # Intermediates for LayerQSolver
              file :q
              file :values, :csv
            end

            file :values
            file :policy
            file :alternate_actions

            folder :tranche do
              key :threshold, type: Float
              key :alternate_actions, type: :boolean

              folder :output_fragment do
                key :input_sum, type: Integer, format: '%04d'
                key :input_max_value, type: Integer, format: '%x'
                key :batch, type: Integer, format: '%04d'

                file :transient
                file :wins
                file :losses
              end

              folder :fragment do
                key :batch, type: Integer, format: '%04d'

                file :bit_set
                file :transient_pr
              end

              file :bit_set
              file :transient_pr
              file :transient
              file :wins # will only exist in parts w/ max_value = max_exponent
              file :losses
            end
          end
        end

        file :tranche, :csv do
          key :discount, type: Float
          key :method, type: Symbol
          key :alternate_action_tolerance, type: Float
          key :threshold, type: Float
          key :alternate_actions, type: :boolean
        end

        folder :simulation do
          key :discount, type: Float
          key :method, type: Symbol
          key :alternate_action_tolerance, type: Float
          key :n, type: Integer
          key :seed, type: Integer
          key :alternate_actions, type: :boolean

          file :transient, :csv
          file :wins, :csv
          file :losses, :csv
          file :moves_to_win, :csv
          file :moves_to_lose, :csv
        end
      end
    end
  end

  class Data
    ROOT = File.join('.', 'data')

    class Game
      class Model
        #
        # Hash model as compressed, line-oriented JSON.
        #
        class HashJsonBz2
          include Storage

          def each_model_state_actions_line
            bunzip(to_s) do |input|
              input.each_line do |line|
                next if line.start_with?('{')
                break if line.start_with?('}')
                raise "bad line: #{line}" unless
                line =~ /^\s*"(\[(?:\d+, )+\d\])": (\{.+}),?$/
                yield Regexp.last_match(1), Regexp.last_match(2)
              end
            end
          end

          def each_model_state_actions
            each_model_state_actions_line do |state_string, actions_string|
              state = json_string_to_state(state_string)
              actions = read_transition_hash(JSON.parse(actions_string))
              yield state, actions
            end
          end

          def read_transition_hash(actions_hash)
            actions_hash.map do |action, successors|
              new_successors = successors.map do |state1, data|
                [json_string_to_state(state1), data]
              end.to_h
              [action.to_sym, new_successors]
            end.to_h
          end

          def read_states
            states = []
            each_model_state_actions_line do |state_string, _actions_string|
              states << json_string_to_state(state_string)
            end
            states
          end

          def read
            hash = read_bzipped_json(to_s)
            hash = hash.map do |state0, actions|
              [json_string_to_state(state0), read_transition_hash(actions)]
            end.to_h
            FiniteMDP::HashModel.new(hash)
          end
        end

        #
        # Array model as uncompressed, Marshaled data.
        #
        class ArrayBin
          def write(array_model)
            File.open(to_s, 'wb') do |file|
              Marshal.dump array_model, file
            end
          end
        end

        #
        # Array model as compressed, Marshaled data.
        #
        class ArrayBinBz2
          include Storage

          def read
            # rubocop:disable Security/MarshalLoad --- assuming trusted data
            bunzip(to_s) { |input| Marshal.load(input) }
            # rubocop:enable Security/MarshalLoad
          end
        end

        class Solution
          #
          # Compressed solution CSV
          #
          class SolutionCsvBz2
            include Storage

            def estimate_state_count
              `bunzip2 < #{self} | wc -l`.to_i - 2
            end

            def read_policy_and_value_from_csv(csv)
              policy = {}
              value = Hash.new { 0 }
              csv.each do |row|
                state = json_string_to_state(row[0])
                policy[state] = row[1].to_sym
                value[state] = row[2].to_f
              end
              [policy, value]
            end

            def read_policy_and_value
              read_bzipped_csv(to_s) do |csv|
                read_policy_and_value_from_csv(csv)
              end
            end
          end
        end
      end
    end
  end
end
