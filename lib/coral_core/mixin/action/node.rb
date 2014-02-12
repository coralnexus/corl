
module Coral
module Mixin
module Action
module Node
        
  #-----------------------------------------------------------------------------
  # Settings
  
  def node_config
    node_plugins = Plugin.loaded_plugins(:node)
    
    register :parallel, :bool, true, 'coral.core.mixins.node.options.parallel'
    register :net_provider, :str, :default, 'coral.core.mixins.node.options.net_provider' do |value|
      value           = value.to_sym
      network_plugins = Plugin.loaded_plugins(:network)
      
      unless network_plugins.keys.include?(value)
        warn('coral.core.mixins.node.errors.network_provider', { :value => value, :choices => network_plugins.keys.join(", ") })
        next false 
      end
      true
    end
    register :node_provider, :str, :local, 'coral.core.mixins.node.options.node_provider' do |value|
      value = value.to_sym
      
      unless node_plugins.keys.include?(value)
        warn('coral.core.mixins.node.errors.node_provider', { :value => value, :choices => node_plugins.keys.join(", ") })
        next false
      end
      true  
    end
    register :nodes, :array, [], 'coral.core.mixins.node.options.nodes' do |values|
      success = true
      values.each do |value|
        if info = Plugin::Node.translate_reference(value)
          if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
            warn('coral.core.mixins.node.errors.nodes', { :value => value, :provider => info[:provider],  :name => info[:name] })
            success = false
          end
        end
      end
      success
    end
  end
  
  #---
         
  def node_ignore
    [ :parallel, :net_provider, :node_provider, :nodes ]
  end
     
  #-----------------------------------------------------------------------------
  # Operations
        
  def node_exec
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
      nodes = translate_node_references(settings[:nodes], network)
      
      Coral.batch(settings[:parallel]) do |op, batch|
        if op == :add
          # Add batch operations      
          nodes.each do |node|
            batch.add(node.name) do
              exec_config = Config.new(settings)
              exec_config.delete(:parallel)
              exec_config.delete(:nodes)
              exec_config.delete(:node_provider)
              
              result = node.action(plugin_provider, exec_config)
              result.status
            end
          end
        else
          # Reduce to single status
          batch.each do |name, status_code|
            if status_code != code.success
              self.status = code.batch_error
              break
            end
          end
        end
      end
    else
      # Execute statement locally
      node = local_node(network)
      
      if validate(node, network)
        yield(node, network) if block_given?
      else
        puts "\n" + I18n.t('coral.core.exec.help.usage') + ': ' + help + "\n" unless quiet?
        self.status = code.validation_failed 
      end
    end
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
    
    network.each_node! do |provider, node_name, node|
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
    
    network.each_node! do |provider, node_name, node|
      if node.public_ip == ip_address
        local_node = node
        local_node.localize
        break
      end
    end
    
    if local_node.nil?
      node_name  = Util::Data.ensure_value(lookup(:hostname), ip_address)    
      local_node = Coral.node(node_name, extended_config(:local_node).import({ :meta => { :parent => network }}), :local)            
    end
    
    local_node
  end
  protected :local_node
end
end
end
end
