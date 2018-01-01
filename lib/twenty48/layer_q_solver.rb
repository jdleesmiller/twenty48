# frozen_string_literal: true

require 'parallel'
require 'tmpdir'

module Twenty48
  #
  # Solver that works backwards through the layers constructed by the
  # LayerBuilder. It also uses a map-reduce approach: we break the layer that
  # is being solved into batches in order to parallelise the solve.
  #
  # The goal is to avoid loading the values for more than one part into memory
  # at once. To do this, we materialize the function Q(s, a) that gives the
  # expected value of successors given the action. The value V(s) is then
  # $\max_a Q(s, a)$. For a given layer, each Q entry starts at zero, and then
  # we make four passes through the layer, one for each of the four possible
  # successor parts.
  #
  # idea: mmap value function for (m, k)
  # we can hit that part from (m-2, k), (m-4, k), (m-2, k-1), (m-4, k-1)
  # initialize a Q for each of those, if a Q doesn't already exist
  # call solve for each of those parts
  # within each part, can still parallelize
  # and we can parallelize between parts
  # then mmap the value function for (m, k + 1)
  # we can hit that part from (m-2, k+1), (m-4, k+1), (m-2, k), (m-4, k)
  # so we can reuse the Q for those; need to make sure that there are no
  # Q's the first time; maybe just keep a list of the Qs we know about.
  # eventually we run out of parts with sum m
  # at this point, we know that all parts with sum m-2 are ready to be
  # finished --- Q converted to V and policy generated
  # then repeat with layer m-2
  #
  class LayerQSolver < LayerSolver
    LayerFragmentQName = KeyValueName.new do |n|
      n.include_keys LayerPartName
      n.key :batch, type: Numeric, format: '%04d'
      n.extension :q
    end

    def solve
      all_parts = find_all_parts
      # Solve layer m and then reduce (convert Q to V and pi) layer m - 2.
      all_parts.keys.reduce do |high_sum, low_sum|
        GC.start
        all_parts[high_sum].each do |max_value|
          q_solve_part(high_sum, max_value)
        end
        GC.start
        all_parts[low_sum].each do |max_value|
          q_reduce_part(low_sum, max_value)
        end
        low_sum
      end
    end

    # Find all actually extant parts and also their potentially reachable
    # successor parts, including parts that would contain win states, in order.
    def find_all_parts
      parts = Hash.new { |h, k| h[k] = Set.new }
      find_actual_parts.each do |(sum, max_value)|
        [0, 2, 4].each do |delta_sum|
          [0, 1].each do |delta_max_value|
            parts[sum + delta_sum] << max_value + delta_max_value
          end
        end
      end
      Hash[parts.keys.sort.reverse.map { |sum| [sum, parts[sum].to_a.sort] }]
    end

    def find_actual_parts
      LayerPartName.glob(layer_folder).map do |name|
        [name.sum, name.max_value]
      end
    end

    def q_solve_part(sum, max_value)
      values_pathname = find_values_part_pathname(sum, max_value)
      native_solver = NativeLayerQSolver.create(
        board_size, valuer, sum, max_value, values_pathname
      )
      jobs = make_solve_q_jobs_for_part(sum, max_value)
      log_solve_layer(sum, max_value, jobs.size)
      run_solve_q_jobs(native_solver, jobs)
    end

    def q_reduce_part(sum, max_value)
      convert_q_to_v(sum, max_value)
      reduce_layer_part(sum, max_value)
    end

    def make_solve_q_jobs_for_part(sum, max_value)
      jobs = []
      find_predecessor_parts(sum, max_value).each do |pred_sum, pred_max_value|
        batches = make_layer_part_batches(pred_sum, pred_max_value)
        batches.each do |index, offset, previous, batch_size|
          jobs << QJob.new(
            self, pred_sum, pred_max_value, index, offset, previous, batch_size
          )
        end
      end
      jobs
    end

    def run_solve_q_jobs(native_solver, jobs)
      jobs.each(&:initialize_q)
      GC.start
      Parallel.each(jobs) do |job|
        job.solve(native_solver)
      end
    end

    def convert_q_to_v(sum, max_value)
      jobs = make_finish_q_jobs_for_part(sum, max_value)
      GC.start
      Parallel.each(jobs, &:finish)
    end

    def make_finish_q_jobs_for_part(sum, max_value)
      batches = make_layer_part_batches(sum, max_value)
      batches.map do |index, offset, previous, batch_size|
        QJob.new(
          self, sum, max_value, index, offset, previous, batch_size
        )
      end
    end

    def find_values_part_pathname(sum, max_value)
      values_pathname = LayerPartValuesName.new(sum: sum, max_value: max_value)
        .in(values_folder)
      return nil if file_size_if_exists(values_pathname) == 0
      values_pathname
    end

    def find_predecessor_parts(sum, max_value)
      predecessor_sums = [sum - 2, sum - 4]
      predecessor_max_values = [max_value - 1, max_value]
      predecessor_sums.product(predecessor_max_values)
    end

    QJob = Struct.new(
      :solver,
      :sum,
      :max_value,
      :index,
      :byte_offset,
      :previous,
      :batch_size
    ) do
      def initialize_q
        return if File.exist?(q_pathname)
        byte_size = batch_size * 32
        block_size = 1024**2
        count = (byte_size.to_f / block_size).ceil
        command = "dd if=/dev/zero of=#{q_pathname}" \
          " bs=#{block_size} count=#{count}" \
          ' >/dev/null 2>/dev/null'
        system command
      end

      def solve(native_solver)
        native_solver.solve(make_vbyte_reader, q_pathname)
      end

      def finish
        NativeLayerQSolver.klass(solver.board_size).finish(
          make_vbyte_reader, q_pathname,
          layer_fragment_values_pathname,
          layer_fragment_policy_pathname
        )
        FileUtils.rm_f q_pathname
      end

      private

      def make_vbyte_reader
        VByteReader.new(states_pathname, byte_offset, previous, batch_size)
      end

      def states_pathname
        LayerPartName.new(
          sum: sum, max_value: max_value
        ).in(solver.layer_folder)
      end

      def q_pathname
        LayerFragmentQName.new(
          sum: sum, max_value: max_value, batch: index
        ).in(solver.values_folder)
      end

      def layer_fragment_values_pathname
        LayerFragmentValuesName.new(
          sum: sum, max_value: max_value, batch: index
        ).in(solver.values_folder)
      end

      def layer_fragment_policy_pathname
        LayerFragmentPolicyName.new(
          sum: sum, max_value: max_value, batch: index
        ).in(solver.values_folder)
      end
    end
  end
end
