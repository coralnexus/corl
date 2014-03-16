
module CORL
module Mixin
module Lookup

  #-----------------------------------------------------------------------------
  # Facter lookup
  
  def facts
    fact_map = {}
    
    CORL.silence do
      Facter.list.each do |name|
        fact_map[name] = Facter.value(name)
      end
    end
    
    fact_map
  end
  
  def fact(name)
    CORL.silence do
      Facter.value(name)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Hiera configuration
  
  @@hiera = nil
  
  #---
  
  def hiera_config
    config_file = CORL.value(:hiera_config_file, File.join(Hiera::Util.config_dir, 'hiera.yaml'))
    config      = {}

    if config_file && File.exist?(config_file)
      config = Hiera::Config.load(config_file)
    end
    config[:logger] = :corl
    
    results = CORL.config(:hiera_config, { :config => config })
    results[:config]
  end
  
  #---

  def hiera
    @@hiera = Hiera.new(:config => hiera_config) if @@hiera.nil?
    @@hiera
  end
  
  #-----------------------------------------------------------------------------
  # Configuration lookup interface
      
  def config_initialized?
    ready = false
    if CORL.admin? && hiera && network_path = fact(:corl_network)
      ready = File.directory?(File.join(network_path, 'config')) ? true : false
    end
    ready
  end
  
  #---
    
  def lookup(properties, default = nil, options = {})
    config      = Config.ensure(options)
    value       = nil
    
    provisioner = config.get(:provisioner, nil)
    
    hiera_scope = config.get(:hiera_scope, {})
    override    = config.get(:override, nil)
    context     = config.get(:context, :priority)    
    
    return_property = config.get(:return_property, false)
    
    unless properties.is_a?(Array)
      properties = [ properties ].flatten
    end

    first_property = nil
    properties.each do |property|
      property       = property.to_sym
      first_property = property unless first_property
      
      # Try to load facts first (these can not be overridden)
      unless value = fact(property)
        if CORL.admin? 
          if config_initialized?
            # Try to find in Hiera data store (these might be security sensitive)
            unless hiera_scope.respond_to?('[]')
              hiera_scope = Hiera::Scope.new(hiera_scope)
            end
            value = hiera.lookup(property.to_s, nil, hiera_scope, override, context)
          end 
    
          if provisioner && Util::Data.undef?(value)
            # Search the provisioner scope (only admins can provision a machine)
            value = CORL.provisioner({ :name => :lookup }, provisioner).lookup(property, default, config)
          end
        end
      end
    end
    value = default if Util::Data.undef?(value) # Resort to default
    value = Util::Data.value(value)
    
    if ! Config.get_property(first_property) || ! Util::Data.undef?(value)
      Config.set_property(first_property.to_s, value)
    end
    
    return value, first_property if return_property
    value
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
       
    Config.set_property(property.to_s, value)
    value
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
    
    Config.set_property(property.to_s, value)
    value
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
    results
  end
end
end
end
