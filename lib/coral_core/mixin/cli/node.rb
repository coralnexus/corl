
module Coral
module Mixin
module CLI
module Node
        
  #-----------------------------------------------------------------------------
  # Options
         
  def node_options(parser)
    parser.option_bool(:parallel, true, 
      '--[no-]parallel', 
      'coral.core.mixins.node.options.parallel'
    )
    parser.option_str(:net_provider, :default, 
      '--net-provider PROVIDER', 
      'coral.core.mixins.node.options.net_provider'
    )
    parser.option_str(:node_provider, :rackspace, 
      '--node-provider PROVIDER', 
      'coral.core.mixins.node.options.node_provider'
    )
    parser.option_array(:nodes, [],
      '--nodes NODE_REFERENCE,...',
      'coral.core.mixins.node.options.nodes'  
    )
  end
        
  #-----------------------------------------------------------------------------
  # Operations
        
  def node_exec
    success = false
    
    # Load network if it exists
    network_config = extended_config(:network, {
      :directory => Dir.pwd,
      :file_name => Coral.config_file
    })
    
    network = Coral.network(
      Coral.sha1(network_config), 
      network_config, 
      options[:net_provider]
    )
    
    if network.has_nodes? && ! options[:nodes].empty?
      # Execute action on remote nodes      
      nodes   = translate_node_references(options[:nodes], network)
      success = true
      
      success = Coral.batch(options[:parallel]) do |batch|      
        nodes.each do |node|
          batch.add(node.name) do 
            node.action(plugin_provider, params)
          end
        end
      end
    else
      # Execute statement locally
      success = yield(local_node(network), network) if block_given?
    end
    success
  end
        
  #-----------------------------------------------------------------------------
  # Utilities
  
  def translate_node_references(references, network)
    node_map = {}
    
    references.each do |reference|
      info = Plugin::Node.translate_reference(reference)
      
      unless info
        info = { :provider => options[:node_provider], :name => reference }
      end
      
      provider = info[:provider].to_sym
      
      node_map[provider] = [] unless node_map.has_key?(provider)
      node_map[provider] << info[:name]
    end
    
    node_groups = []
    network.nodes.each do |provider, nodes|
      nodes.each do |node_name, node|
        node_groups << node.search(:groups)
      end
    end
    
    return node_map.values  
  end
  protected :translate_node_references
  
  #---
  
  def local_node(network)
    
  end
end
end
end
end
