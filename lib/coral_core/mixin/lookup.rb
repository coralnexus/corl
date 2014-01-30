
# Should be included via extend
#
# extend Mixin::Lookup
#

module Coral
module Mixin
module Lookup
  #-----------------------------------------------------------------------------
  # Hiera configuration
  
  @@hiera = {}
  
  #---
  
  def hiera_config(provider = :puppet)
    return Coral.provisioner(provider).config
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
      require 'hiera'
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
      first_property = property unless first_property
          
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
    value = default if Util::Data.undef?(value)
    value = Util::Data.value(value)
    
    if ! @@properties.has_key?(first_property) || ! Util::Data.undef?(value)
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
