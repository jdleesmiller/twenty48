# frozen_string_literal: true

module Twenty48
  #
  # Simple directed graph model with dot (graphviz) printer.
  #
  class Graph
    def initialize
      @nodes = {}
      @edges = {}
      @clusters = Hash.new { |h, k| h[k] = [] }
      @cluster_labels = {}
    end

    attr_reader :nodes
    attr_reader :edges
    attr_reader :clusters
    attr_reader :cluster_labels

    def add_node(name, cluster = nil, properties = {})
      raise 'node already added' if node?(name)
      @nodes[name] = properties
      @clusters[cluster] << name if cluster
      properties
    end

    def node?(name)
      @nodes.key?(name)
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
      cluster_names = @clusters.keys.sort
      cluster_dot = cluster_names.map do |cluster_name|
        node_names = @clusters[cluster_name]
        body = [
          %(label="#{cluster_labels[cluster_name] || cluster_name}"),
          'style=filled', 'color=grey95',
          'margin=16',
          node_names.map { |name| "#{name};" }.join(' ')
        ].join('; ')
        "subgraph cluster_#{cluster_name} { #{body} }"
      end
      node_dot = @nodes.map do |node_name, properties|
        "#{node_name} [#{to_key_value(properties).join(', ')}];"
      end
      edge_dot = @edges.map do |(node0_name, node1_name), properties|
        key_values = to_key_value(properties)
        "#{node0_name} -> #{node1_name} [#{key_values.join(', ')}];"
      end
      cluster_dot + node_dot + edge_dot
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
