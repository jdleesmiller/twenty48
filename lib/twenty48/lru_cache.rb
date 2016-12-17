# frozen_string_literal: true

module Twenty48
  #
  # A simple cache with Least Recently Used (LRU) eviction. Based on
  # http://stackoverflow.com/a/16161783/2053820
  #
  # This implementation exploits the fact that hashes are ordered in ruby 1.9+.
  # The key property that this relies on is that new keys are added to the end
  # of the hash.
  #
  class LruCache
    HIT_RATE_ALPHA = 0.01

    def initialize(max_size:)
      raise "bad max_size: #{max_size}" if max_size < 1

      @data = {}
      @max_size = max_size
      @hit_rate = 1
    end

    # Exponential moving average hit rate.
    attr_reader :hit_rate

    def []=(key, value)
      @data.delete(key)
      @data[key] = value
      @data.delete(@data.first[0]) while @data.size > @max_size
      value
    end

    def [](key)
      found = true
      value = @data.delete(key) { found = false }
      @hit_rate *= 1 - HIT_RATE_ALPHA
      return unless found
      @hit_rate += HIT_RATE_ALPHA
      @data[key] = value
      value
    end

    def size
      @data.size
    end
  end
end
