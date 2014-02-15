
module Coral
module Mixin
module Action
module Node
        
  #-----------------------------------------------------------------------------
  # Settings
  
  def node_config
    node_plugins = Manager.connection.loaded_plugins(:node)
    
    register :parallel, :bool, true, 'coral.core.mixins.node.options.parallel'
    register :net_provider, :str, :default, 'coral.core.mixins.node.options.net_provider' do |value|
      value           = value.to_sym
      network_plugins = Manager.connection.loaded_plugins(:network)
      
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
  
  def init_network(path = nil)
    if Coral.admin?
      network_path = lookup(:coral_network)
      Dir.mkdir(network_path) unless File.directory?(network_path)
    else
      network_path = ( path.nil? ? Dir.pwd : File.expand_path(path) )
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
    network  
  end
  
  #---
        
  def node_exec
    network = init_network
    
    #
    # A fork in the road...
    #
    if network.has_nodes? && ! settings[:nodes].empty?
      # Execute action on remote nodes 
      success = network.batch(settings[:nodes], settings[:node_provider], settings[:parallel]) do |node|
        exec_config = Config.new(settings)
        exec_config.delete(:parallel)
        exec_config.delete(:nodes)
        exec_config.delete(:node_provider)
              
        result = node.action(plugin_provider, exec_config) do |op, data|
          execute_remote(node, network, op, data)
        end
        result.status == code.success 
      end
      self.status = code.batch_error unless success
    else
      # Execute statement locally
      node = network.local_node
      
      if validate(node, network)
        yield(node, network) if block_given?
      else
        puts "\n" + I18n.t('coral.core.exec.help.usage') + ': ' + help + "\n" unless quiet?
        self.status = code.validation_failed 
      end
    end
  end
  
  #---
  
  def execute_remote(node, network, op, data)
    ui_group(node.name) do
      data = yield if block_given?
    end
    data  
  end
end
end
end
end
