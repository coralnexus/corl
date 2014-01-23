
# Should be included via extend
#
# extend Mixin::Lookup
#

module Coral
module Mixin
module Lookup
  #-----------------------------------------------------------------------------
  # Hiera configuration
  
  @@hiera = nil
  
  #---
  
  def hiera_config
    config_file = Puppet.settings[:hiera_config]
    config      = {}

    if File.exist?(config_file)
      config = Hiera::Config.load(config_file)
    else
      ui.warn("Config file #{config_file} not found, using Hiera defaults")
    end

    config[:logger] = 'puppet'
    return config
  end
  
  #---

  def hiera
    @@hiera = Hiera.new(:config => hiera_config) unless @@hiera
    return @@hiera
  end
  
  #-----------------------------------------------------------------------------
  # Configuration lookup interface
      
  def initialized?(options = {})
    config   = Config.ensure(options)
    
    begin
      require 'hiera'
      puppet_scope = config.get(:puppet_scope, scope)
    
      prefix_text = config.get(:prefix_text, '::')  
      init_fact   = prefix_text + config.get(:init_fact, 'hiera_ready')
      
      if Puppet::Parser::Functions.function('hiera') && puppet_scope.respond_to?('[]')
        return true if Util::Data.true?(puppet_scope[init_fact])
      end
      return false
    
    rescue Exception # Prevent abortions.
    end    
    return false
  end
  
  #---
    
  def lookup(properties, default = nil, options = {})
    config          = Config.ensure(options)
    value           = nil
    
    hiera_scope     = config.get(:hiera_scope, {})
    context         = config.get(:context, :priority)    
    override        = config.get(:override, nil)
    
    puppet_scope    = config.get(:puppet_scope, {})
    
    base_names      = config.get(:search, nil)
     
    search_name     = config.get(:search_name, true)
    reverse_lookup  = config.get(:reverse_lookup, true)
    
    return_property = config.get(:return_property, false)
    
    unless properties.is_a?(Array)
      properties = [ properties ].flatten
    end

    first_property = nil
    properties.each do |property|
      first_property = property unless first_property
          
      if initialized?(config)
        unless hiera_scope.respond_to?('[]')
          hiera_scope = Hiera::Scope.new(hiera_scope)
        end
        value = hiera.lookup(property, nil, hiera_scope, override, context)
      end 
    
      if Util::Data.undef?(value) && puppet_scope.respond_to?(:lookupvar)    
        log_level = Puppet::Util::Log.level
        Puppet::Util::Log.level = :err # Don't want failed parameter lookup warnings here.
      
        if base_names
          if base_names.is_a?(String)
            base_names = [ base_names ]
          end
          base_names = base_names.reverse if reverse_lookup
        
          base_names.each do |base|
            value = puppet_scope.lookupvar("::#{base}::#{property}")
            break unless Util::Data.undef?(value)  
          end
        end
        if Util::Data.undef?(value) && search_name
          value = puppet_scope.lookupvar("::#{property}")
        end
        Puppet::Util::Log.level = log_level
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
end
end
end
