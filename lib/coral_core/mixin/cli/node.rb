
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
  # Facter configuration
  
  @@facts = {}
  
  def init_facts(reset = false)
    if reset || @@facts.empty?
      Facter.list.each do |name|
        @@facts[name] = Facter.value(name)
      end
    end
  end
  
  #---
  
  def facts(reset = false)
    init_facts(reset)
    @@facts
  end
  
  def fact(name, reset = false)
    init_facts(reset)
    @@facts[name]
  end
  
  #-----------------------------------------------------------------------------
  # Hiera configuration
  
  @@hiera = {}
  
  #---
  
  def hiera_config(provider = :puppet)
    return Coral.provisioner(provider).hiera_config
  end
  
  #---

  def hiera(provider = :puppet)
    @@hiera[provider] = Hiera.new(:config => hiera_config(provider)) unless @@hiera.has_key?(provider)
    return @@hiera[provider]
  end
  
  #-----------------------------------------------------------------------------
  # Configuration lookup interface
      
  def initialized?(options = {})
    config   = Config.ensure(options)
    provider = config.get(:provisioner, nil)
    begin
      return true unless provider      
      return Coral.provisioner(provider).initialized?(config)
    
    rescue Exception # Prevent abortions.
    end    
    return false
  end
  
  #---
    
  def lookup(properties, default = nil, options = {})
    config          = Config.ensure(options)
    value           = nil
    
    provider        = config.get(:provisioner, :puppet)
    
    hiera_scope     = config.get(:hiera_scope, {})
    context         = config.get(:context, :priority)    
    override        = config.get(:override, nil)
    
    return_property = config.get(:return_property, false)
    
    unless properties.is_a?(Array)
      properties = [ properties ].flatten
    end

    first_property = nil
    properties.each do |property|
      property       = property.to_sym
      first_property = property unless first_property
      
      unless value = fact(property)
        if initialized?(config)
          unless hiera_scope.respond_to?('[]')
            hiera_scope = Hiera::Scope.new(hiera_scope)
          end
          value = hiera(provider).lookup(property, nil, hiera_scope, override, context)
        end 
    
        if Util::Data.undef?(value)
          value = Coral.provisioner(provider).lookup(property, default, config)
        end
      end
    end
    value = default if Util::Data.undef?(value)
    value = Util::Data.value(value)
    
    if ! Config::Collection.get(first_property) || ! Util::Data.undef?(value)
      Config::Collection.set(first_property, value)
    end
    return value, first_property if return_property
    return value
  end
    
  #---
  
  def lookup_array(properties, default = [], options = {})
    config          = Config.ensure(options) 
    value, property = lookup(properties, nil, config.import({ :return_property => true }))
    
    if Util::Data.undef?(value)
      value = default
        
    elsif ! Util::Data.empty?(default)
      if config.get(:merge, false)
        value = Util::Data.merge([default, value], config)
      end
    end
    
    unless value.is_a?(Array)
      value = ( Util::Data.empty?(value) ? [] : [ value ] )
    end
    
    Config::Collection.set(property, value)
    return value
  end
    
  #---
  
  def lookup_hash(properties, default = {}, options = {})
    config          = Config.ensure(options) 
    value, property = lookup(properties, nil, config.import({ :return_property => true }))
    
    if Util::Data.undef?(value)
      value = default
        
    elsif ! Util::Data.empty?(default)
      if config.get(:merge, false)
        value = Util::Data.merge([default, value], config)
      end
    end
    
    unless value.is_a?(Hash)
      value = ( Util::Data.empty?(value) ? {} : { :value => value } )
    end
    
    Config::Collection.set(property, value)
    return value
  end
  
  #---

  def normalize(data, override = nil, options = {})
    config  = Config.ensure(options)
    results = {}
    
    unless Util::Data.undef?(override)
      case data
      when String, Symbol
        data = [ data, override ] if data != override
      when Array
        data << override unless data.include?(override)
      when Hash
        data = [ data, override ]
      end
    end
    
    case data
    when String, Symbol
      results = lookup(data.to_s, {}, config)
      
    when Array
      data.each do |item|
        if item.is_a?(String) || item.is_a?(Symbol)
          item = lookup(item.to_s, {}, config)
        end
        unless Util::Data.undef?(item)
          results = Util::Data.merge([ results, item ], config)
        end
      end
  
    when Hash
      results = data
    end
    
    return results
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
      settings[:net_provider]
    )
    
    if network.has_nodes? && ! settings[:nodes].empty?
      # Execute action on remote nodes      
      nodes   = translate_node_references(settings[:nodes], network)
      success = Coral.batch(settings[:parallel]) do |batch|      
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
    
    network.nodes.each do |provider, nodes|
      nodes.each do |node_name, node|
        node.search(:groups, [], :array).each do |group|
          groups[group] = [] unless groups.has_key?(group)
          groups[group] << { :provider => provider, :name => node_name }
        end
      end
    end
    
    groups
  end
  protected :node_groups
  
  #---
  
  def local_node(network)    
    ip_address = lookup(:ipaddress)
        
    nil  # Coming soon 
  end
  protected :local_node
end
end
end
end
