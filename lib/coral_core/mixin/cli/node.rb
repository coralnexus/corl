
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
      node_map = translate_node_references(options[:nodes])
            
      network.nodes.each do |provider, nodes|
        nodes.each do |node_name, node|
          
        end
      end
      
      success = true
    else
      # Execute statement locally
      success = yield if block_given?
    end
    success
  end
        
  #-----------------------------------------------------------------------------
  # Utilities
  
  def translate_node_references(references)
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
    return node_map  
  end
  protected :translate_node_references
end
end
end
end
