module Twenty48
  #
  # Simple directed graph model with dot (graphviz) printer.
  #
  class Graph
    def initialize
      @nodes = {}
      @edges = {}
    end

    attr_reader :nodes
    attr_reader :edges

    def add_node(name, properties = {})
      fail 'node already added' if @nodes.key?(name)
      @nodes[name] = properties
    end

    def add_edge(node0_name, node1_name, properties = {})
      @edges[[node0_name, node1_name]] = properties
    end

    def remove_non_maximal_edges
      # TODO
    end

    def remove_edges_below_weight(_threshold)
      # TODO
    end

    def remove_unreachable_nodes
      # TODO
    end

    def to_dot
      @nodes.map do |node_name, properties|
        "#{node_name} [#{to_key_value(properties).join(', ')}];"
      end +
      @edges.map do |(node0_name, node1_name), properties|
        key_values = to_key_value(properties)
        "#{node0_name} -> #{node1_name} [#{key_values.join(', ')}];"
      end
    end

    private

    def to_key_value(properties)
      properties.map do |name, value|
        if value.is_a?(Numeric) || value.is_a?(Symbol)
          "#{name}=#{value}"
        else
          "#{name}=\"#{value}\""
        end
      end
    end
  end
end
