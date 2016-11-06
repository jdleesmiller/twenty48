# frozen_string_literal: true

module Twenty48
  #
  # A no-op implementation of LRU cache, for when we don't actually want to
  # bother with caching.
  #
  class NonCache
    def initialize(max_size: 0)
    end

    def hit_rate
      0
    end

    def []=(_key, value)
      value
    end

    def [](_key)
      nil
    end

    def size
      0
    end
  end
end
