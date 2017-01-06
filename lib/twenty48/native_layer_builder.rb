# frozen_string_literal: true

require 'tmpdir'

module Twenty48
  #
  # Common methods for the native LayerBuilder class.
  #
  module NativeLayerBuilder
    def self.create(board_size, resolver)
      klass = case board_size
              when 2 then LayerBuilder2
              when 3 then LayerBuilder3
              when 4 then LayerBuilder4
              else raise "bad layer builder board_size: #{board_size}"
              end
      klass.new(resolver)
    end
  end

  #
  # Layered statespace builder for 2x2 boards.
  #
  class LayerBuilder2
    include NativeLayerBuilder

    def board_size
      2
    end
  end

  #
  # Layered statespace builder for 3x3 boards.
  #
  class LayerBuilder3
    include NativeLayerBuilder

    def board_size
      3
    end
  end

  #
  # Layered statespace builder for 4x4 boards.
  #
  class LayerBuilder4
    include NativeLayerBuilder

    def board_size
      4
    end
  end
end
