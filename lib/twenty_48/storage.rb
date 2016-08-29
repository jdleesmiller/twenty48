# frozen_string_literal: true
module Twenty48
  #
  # Utilities for reading and writing things from and to disk.
  #
  module Storage
    module_function

    ROOT = File.join('.', 'data')
    MODELS_PATH = File.join(ROOT, 'models')
    SOLVERS_PATH = File.join(ROOT, 'solvers')
    GRAPHS_PATH = File.join(ROOT, 'graphs')

    MODELS_GLOB = File.join(MODELS_PATH, '*.json.bz2')
    SOLVERS_GLOB = File.join(SOLVERS_PATH, '*.csv.bz2')

    def build_basename(**args)
      args.map { |key, value| "#{key}-#{value}" }.join('_')
    end

    def build_pathname_rx(*components)
      Regexp.new(components.map(&:to_s).join('_'))
    end

    def rx_captures_to_hash(match_data)
      match_data.names.map(&:to_sym).zip(match_data.captures).to_h
    end

    MODEL_NAME_RX = build_pathname_rx(
      /board_size-(?<board_size>\d+)/,
      /max_exponent-(?<max_exponent>\d+)/,
      /max_end_state_moves-(?<max_end_state_moves>\d+)/
    )

    SOLVER_NAME_RX = build_pathname_rx(
      MODEL_NAME_RX,
      /discount-(?<discount>[0-9.e+-]+)/,
      /tolerance-(?<tolerance>[0-9.e+-]+)/
    )

    def bunzip(pathname)
      IO.popen("bunzip2 < #{pathname}") { |input| yield(input) }
    end

    def read_bzipped_json(pathname)
      bunzip(pathname) { |input| JSON.load(input) }
    end

    def read_bzipped_csv(pathname, options = { headers: :first_row })
      bunzip(pathname) { |input| yield(CSV(input, options)) }
    end

    #
    # Model path handling
    #

    def model_params_from_builder(builder)
      {
        board_size: builder.board_size,
        max_exponent: builder.max_exponent,
        max_end_state_moves: builder.max_end_state_moves
      }
    end

    def model_params_from_pathname(pathname)
      basename = File.basename(pathname)
      raise "no model in #{pathname}" unless basename =~ MODEL_NAME_RX
      cast_model_params(rx_captures_to_hash(Regexp.last_match))
    end

    def cast_model_params(params)
      params[:board_size] = params[:board_size].to_i
      params[:max_exponent] = params[:max_exponent].to_i
      params[:max_end_state_moves] = params[:max_end_state_moves].to_i
      params
    end

    def model_basename(model_params)
      build_basename(
        board_size: model_params[:board_size],
        max_exponent: model_params[:max_exponent],
        max_end_state_moves: model_params[:max_end_state_moves]
      )
    end

    def model_pathname(model_params, extension = '.json.bz2')
      File.join(MODELS_PATH, "#{model_basename(model_params)}#{extension}")
    end

    #
    # Solver path handling
    #

    # The solver doesn't actually let us get the discount, and the tolerance
    # is not stored on the solver.
    def solver_params(model_params, discount, tolerance)
      model_params.merge(
        discount: discount,
        tolerance: tolerance
      )
    end

    def solver_params_from_pathname(pathname)
      basename = File.basename(pathname)
      raise "no solver in #{pathname}" unless basename =~ SOLVER_NAME_RX
      cast_solver_params(rx_captures_to_hash(Regexp.last_match))
    end

    def cast_solver_params(params)
      cast_model_params(params)
      params[:discount] = params[:discount].to_f
      params[:tolerance] = params[:tolerance].to_f
      params
    end

    def solver_basename(solver_params)
      build_basename(solver_params)
    end

    def solver_pathname(solver_params, extension = '.csv.bz2')
      File.join(SOLVERS_PATH, "#{solver_basename(solver_params)}#{extension}")
    end

    #
    # Dot graph path handling
    #

    def graph_pathname(solver_params, extension = '.dot.bz2')
      File.join(GRAPHS_PATH, "#{solver_basename(solver_params)}#{extension}")
    end

    #
    # Read model builder
    #

    def new_builder_from_model_params(model_params)
      Model.new(
        model_params[:board_size],
        model_params[:max_exponent],
        model_params[:max_end_state_moves]
      )
    end

    #
    # Read MDP model
    #

    def string_to_state(string)
      Twenty48::State.new(JSON.parse(string))
    end

    def read_model(model_params)
      pathname = model_pathname(model_params)
      hash = read_bzipped_json(pathname)
      hash = hash.map do |state0, actions|
        new_actions = actions.map do |action, successors|
          new_successors = successors.map do |state1, data|
            [string_to_state(state1), data]
          end.to_h
          [action.to_sym, new_successors]
        end.to_h
        [string_to_state(state0), new_actions]
      end.to_h
      FiniteMDP::HashModel.new(hash)
    end

    #
    # Read solver
    #

    def read_policy_and_value_from_csv(csv)
      policy = {}
      value = Hash.new { 0 }
      csv.each do |row|
        state = string_to_state(row[0])
        policy[state] = row[1].to_sym
        value[state] = row[2].to_f
      end
      [policy, value]
    end

    def read_solver(solver_params)
      model = read_model(solver_params)
      pathname = solver_pathname(solver_params)
      policy, value = read_bzipped_csv(pathname) do |csv|
        read_policy_and_value_from_csv(csv)
      end
      FiniteMDP::Solver.new(model, solver_params[:discount], policy, value)
    end
  end
end
