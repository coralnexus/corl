
module Coral
module Mixin
module Action
module Node
        
  #-----------------------------------------------------------------------------
  # Options
  
  def node_defaults
    settings[:parallel]      = true
    settings[:net_provider]  = :default
    settings[:node_provider] = :local
    settings[:nodes]         = []
  end
  
  #---
         
  def node_options(parser)
    parser.option_bool(:parallel, true, 
      '--[no-]parallel', 
      'coral.core.mixins.node.options.parallel'
    )
    parser.option_str(:net_provider, :default, 
      '--net-provider PROVIDER', 
      'coral.core.mixins.node.options.net_provider'
    )
    parser.option_str(:node_provider, :local, 
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
    status = code.unknown_status
    
    if Coral.admin?
      network_path = lookup(:coral_network)
      Dir.mkdir(network_path) unless File.directory?(network_path)
    else
      network_path = Dir.pwd
    end
    
    # Load network if it exists
    network_config = extended_config(:network, {
      :directory => network_path,
      :file_name => Coral.config_file
    })
    
    network = Coral.network(
      Coral.sha1(network_config), 
      network_config, 
      settings[:net_provider]
    )
    
    if network.has_nodes? && ! settings[:nodes].empty?
      # Execute action on remote nodes      
      nodes  = translate_node_references(settings[:nodes], network)
      status = Coral.batch(settings[:parallel]) do |op, batch|
        if op == :add
          # Add batch operations      
          nodes.each do |node|
            batch.add(node.name) do
              exec_config = Config.new(settings)
              exec_config.delete(:parallel)
              exec_config.delete(:nodes)
              exec_config.delete(:node_provider)
              
              results = node.action(plugin_provider, exec_config)
              
              render(results[:result], { :prefix => false }) unless results[:result].empty?
              alert(results[:error], { :prefix => false }) unless results[:error].empty?
              
              results[:status]
            end
          end
        else
          # Reduce to single status
          status = code.success
          
          batch.each do |name, action_status|
            if action_status != code.success
              status = code.batch_error
              break
            end
          end
          
          status  
        end
      end
    else
      # Execute statement locally
      status = yield(local_node(network), network) if block_given?
    end
    status
  end
        
  #-----------------------------------------------------------------------------
  # Utilities
  
  def translate_node_references(references, network)
    info  = node_info(references, network)    
    nodes = []
    
    registered_nodes = network.nodes
    
    info.each do |provider, names|
      provider_nodes = registered_nodes[provider]
      
      names.each do |name|
        nodes << provider_nodes[name]  
      end
    end
    nodes  
  end
  protected :translate_node_references
  
  #---
  
  def node_info(references, network)
    groups    = symbol_map(node_groups(network))
    node_info = {}
    
    references.each do |reference|
      info = Plugin::Node.translate_reference(reference)
      info = { :provider => settings[:node_provider], :name => reference } unless info
      name = info[:name].to_sym     
      
      # Check for group membership
      if groups.has_key?(name)
        groups[name].each do |member_info|
          provider = member_info[:provider].to_sym
          
          node_info[provider] = [] unless node_info.has_key?(provider)        
          node_info[provider] << member_info[:name]
        end
      else
        # Not a group
        provider = info[:provider].to_sym
        
        if network.nodes.has_key?(provider)
          node_found = false
          
          network.nodes(provider).each do |node_name, node|
            if node_name == name
              node_info[provider] = [] unless node_info.has_key?(provider)        
              node_info[provider] << node_name
              node_found = true
              break
            end
          end
          
          unless node_found
            # TODO:  Error or something?
          end
        end 
      end     
    end
    
    node_info  
  end
  protected :node_info
  
  #---
  
  def node_groups(network)
    groups = {}
    
    each_node!(network) do |provider, node_name, node|
      node.groups.each do |group|
        groups[group] = [] unless groups.has_key?(group)
        groups[group] << { :provider => provider, :name => node_name }
      end
    end
    
    groups
  end
  protected :node_groups
  
  #---
  
  def local_node(network)    
    ip_address = lookup(:ipaddress)
    local_node = nil
    
    each_node!(network) do |provider, node_name, node|
      if node.public_ip == ip_address
        local_node = node
        local_node.localize
        break
      end
    end
    
    if local_node.nil?
      node_name  = Util::Data.ensure_value(lookup(:hostname), ip_address)    
      local_node = Coral.node(node_name, extended_config(:local_node), :local)            
    end
    
    local_node
  end
  protected :local_node
  
  #---
  
  def each_node!(network)
    network.nodes.each do |provider, nodes|
      nodes.each do |node_name, node|
        yield(provider, node_name, node)
      end
    end  
  end
  protected :each_node!
end
end
end
end
