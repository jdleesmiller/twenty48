# frozen_string_literal: true

module Twenty48
  #
  # A hash table of States. This tries to use as little memory as
  # possible per state, so it is just an array of states. We use linear
  # probing to resolve collisions, and this is a fixed size table; it
  # does not support growth. States are packed into 64-bit integers to save
  # space.
  #
  class StateHashTable
    MAX_EXPONENT = 11
    RECORD_SIZE = 8 # bytes
    EMPTY_RECORD = ([0] * RECORD_SIZE).pack('C*')

    def initialize(board_size:, size:)
      @board_size = board_size
      @size = size
      @data = [0].pack('C*') * size * RECORD_SIZE
      @count = 0
    end

    attr_reader :board_size
    attr_reader :size
    attr_reader :count

    def fill_factor
      count.to_f / size
    end

    def member?(state)
      _, candidate = find_packed_state(pack(state))
      !candidate.nil?
    end

    def <<(state)
      insert_packed_state(pack(state))
    end

    def pack(state)
      # Add 1 so we can ensure that all states, including the lose state,
      # have non-zero values in the table; that way zero means empty.
      packed_value = 1
      exponent = 1
      state.to_a.each do |value|
        packed_value += value * exponent
        exponent *= MAX_EXPONENT
      end
      [packed_value].pack('Q')
    end

    def unpack(packed_state)
      packed_value = packed_state.unpack('Q')[0]
      packed_value -= 1
      array = (0...(@board_size**2)).map do |_|
        packed_value, value = packed_value.divmod(MAX_EXPONENT)
        value
      end
      State.new(array)
    end

    def to_a
      (0...@size).map do |index|
        packed_state = get(index)
        next nil if packed_state == EMPTY_RECORD
        unpack(packed_state)
      end
    end

    private

    def get(index)
      @data[index * RECORD_SIZE, RECORD_SIZE]
    end

    def set(index, record)
      @data[index * RECORD_SIZE, RECORD_SIZE] = record
    end

    def find_packed_state(packed_state)
      index = packed_state.hash % @size
      loop do
        candidate = get(index)
        return index, candidate if candidate == packed_state
        return index, nil if candidate == EMPTY_RECORD
        index += 1
        index = 0 if index >= @size
      end
    end

    def insert_packed_state(packed_state)
      raise 'State table is full' if @count >= @size
      index, candidate = find_packed_state(packed_state)
      return if candidate == packed_state
      set(index, packed_state)
      @count += 1
      nil
    end
  end
end
