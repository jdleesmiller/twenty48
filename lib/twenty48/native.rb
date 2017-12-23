# frozen_string_literal: true

#
# Native extensions for the Twenty48 solver.
#
module Twenty48
  #
  # Generate the start states for a model.
  #
  def self.generate_start_states(board_size:)
    case board_size
    when 2 then generate_start_states_2
    when 3 then generate_start_states_3
    when 4 then generate_start_states_4
    else raise "bad start states size: #{board_size}"
    end
  end

  #
  # Common methods for the native board State classes.
  #
  module NativeState
    include CommonState

    def self.create_from_nybbles(board_size, nybbles)
      case board_size
      when 2 then Twenty48::State2.new(nybbles)
      when 3 then Twenty48::State3.new(nybbles)
      when 4 then Twenty48::State4.new(nybbles)
      else
        raise "bad state board size: #{board_size}"
      end
    end

    def self.create(state_array)
      case state_array.size
      when 4 then Twenty48::State2.new(state_array)
      when 9 then Twenty48::State3.new(state_array)
      when 16 then Twenty48::State4.new(state_array)
      else
        raise "bad state array size: #{state_array.size}"
      end
    end

    def eql?(other)
      self == other
    end

    def hash
      get_nybbles.hash
    end

    def <=>(other)
      return 0 if self == other
      self < other ? -1 : 1
    end
  end

  #
  # 2x2 board state.
  #
  class State2
    include NativeState

    alias adjacent_pair? has_adjacent_pair

    def board_size
      2
    end
  end

  #
  # 3x3 board state.
  #
  class State3
    include NativeState

    alias adjacent_pair? has_adjacent_pair

    def board_size
      3
    end
  end

  #
  # 4x4 board state.
  #
  class State4
    include NativeState

    alias adjacent_pair? has_adjacent_pair

    def board_size
      4
    end
  end

  #
  # Yield each state in a list of states in compressed vbyte format.
  #
  def self.each_state_vbyte(board_size, pathname)
    vbyte_reader = VByteReader.new(pathname)
    loop do
      nybbles = vbyte_reader.read
      break if nybbles == 0
      yield NativeState.create_from_nybbles(board_size, nybbles)
    end
    vbyte_reader.close
  end

  #
  # Read a list of states in compressed vbyte format.
  #
  def self.read_states_vbyte(board_size, pathname)
    result = []
    each_state_vbyte(board_size, pathname) do |state|
      result << state
    end
    result
  end

  #
  # Write a list of states in compressed vbyte format.
  #
  def self.write_states_vbyte(states, pathname)
    vbyte_writer = VByteWriter.new(pathname)
    states.each do |state|
      vbyte_writer.write(state.get_nybbles)
    end
    vbyte_writer.close
    vbyte_writer.get_bytes_written
  end

  #
  # Write a list of states in hex format.
  #
  def self.write_states_hex(states, pathname)
    if states.empty?
      File.touch pathname
      File.truncate pathname
      return
    end
    case states.first.board_size
    when 2 then write_states_hex_2(states, pathname)
    when 3 then write_states_hex_3(states, pathname)
    when 4 then write_states_hex_4(states, pathname)
    else raise 'write_states_hex: bad board size'
    end
  end

  #
  # An entry in a layer index. See VByteIndex for info.
  #
  class VByteIndexEntry
    def self.from_raw(raw)
      new(raw['byte_offset'], raw['previous'].to_i(16))
    end

    def to_json(*args)
      {
        byte_offset: byte_offset,
        previous: previous.to_s(16)
      }.to_json(*args)
    end
  end

  #
  # Common methods for the native Valuer class.
  #
  module NativeValuer
    def self.create(board_size:, max_exponent:, max_depth:, discount:)
      klass = case board_size
              when 2 then Valuer2
              when 3 then Valuer3
              when 4 then Valuer4
              else raise "bad valuer board_size: #{board_size}"
              end
      klass.new(max_exponent, max_depth, discount)
    end
  end

  #
  # Common methods for the native LayerSolver class.
  #
  module NativeLayerSolver
    def self.create(board_size, *args)
      klass = case board_size
              when 2 then LayerSolver2
              when 3 then LayerSolver3
              when 4 then LayerSolver4
              else raise "bad layer solver board_size: #{board_size}"
              end
      klass.new(*args)
    end
  end

  #
  # Common methods for the native StateValueMap classes.
  #
  module NativeStateValueMap
    def self.create(board_size)
      klass = case board_size
              when 2 then StateValueMap2
              when 3 then StateValueMap3
              when 4 then StateValueMap4
              else raise "bad layer solver board_size: #{board_size}"
              end
      klass.new
    end

    def each
      (0...size).each do |index|
        state = get_state(index)
        yield state, get_action(state), get_value(state)
      end
    end
  end

  #
  # Value and action map for 2x2 states.
  #
  class StateValueMap2
    include NativeStateValueMap
  end

  #
  # Value and action map for 3x3 states.
  #
  class StateValueMap3
    include NativeStateValueMap
  end

  #
  # Value and action map for 4x4 states.
  #
  class StateValueMap4
    include NativeStateValueMap
  end

  #
  # Read packed policy files.
  #
  class PolicyReader
    #
    # Read full policy into array.
    #
    def self.read(pathname, num_states, skip: 0)
      reader = PolicyReader.new(pathname)
      reader.skip skip
      Array.new(num_states - skip) { reader.read }
    end
  end
end
