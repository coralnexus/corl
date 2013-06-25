
module Coral
class Config
  
  #-----------------------------------------------------------------------------
  # Global configuration
  
  @@hiera = {}
  
  #---
  
  def self.hiera_config(provider = :puppet)
    return Coral.provisioner(provider).hiera_config
  end
  
  #---

  def self.hiera(provider = :puppet)
    @@hiera[provider] = Hiera.new(:config => hiera_config(provider)) unless @@hiera.has_key?(provider)
    return @@hiera[provider]
  end
  
  #---

  def hiera(provider = :puppet)
    return self.class.hiera(provider)
  end
  
  #-----------------------------------------------------------------------------
  # Configuration lookup
      
  def self.initialized?(options = {})
    config   = Config.ensure(options)
    provider = config.get(:provisioner, :puppet)
    begin
      require 'hiera'      
      return Coral.provisioner(provider).initialized?(config)
    
    rescue Exception # Prevent abortions.
    end    
    return false
  end
  
  #---
    
  def self.lookup(properties, default = nil, options = {})
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
      PropertyCollection.set(first_property, value)
    end
    return value, first_property if return_property
    return value
  end
    
  #---
  
  def self.lookup_array(properties, default = [], options = {})
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
    
    PropertyCollection.set(property, value)
    return value
  end
    
  #---
  
  def self.lookup_hash(properties, default = {}, options = {})
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
    
    PropertyCollection.set(property, value)
    return value
  end
  
  #---

  def self.normalize(data, override = nil, options = {})
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
  # Configuration options
  
  def self.contexts(contexts = [], hierarchy = [])
    return Options.contexts(contexts, hierarchy)  
  end
  
  #---
  
  def self.get_options(contexts, force = true)
    return Options.get(contexts, force)  
  end
  
  #---
  
  def self.set_options(contexts, options, force = true)
    Options.set(contexts, options, force)
    return self  
  end
  
  #---
  
  def self.clear_options(contexts)
    Options.clear(contexts)
    return self  
  end
    
  #-----------------------------------------------------------------------------
  # Instance generators
  
  def self.ensure(config)
    case config
    when Coral::Config
      return config
    when Hash
      return new(config) 
    end
    return new
  end
  
  #---
  
  def self.init(options, contexts = [], hierarchy = [], defaults = {})
    contexts = contexts(contexts, hierarchy)
    config   = new(get_options(contexts), defaults)
    config.import(options) unless Util::Data.empty?(options)
    return config
  end
  
  #---
  
  def self.init_flat(options, contexts = [], defaults = {})
    return init(options, contexts, [], defaults)
  end
  
  #-----------------------------------------------------------------------------
  # Configuration instance
    
  def initialize(data = {}, defaults = {}, force = true)
    @force   = force
    @options = {}
    
    if defaults.is_a?(Hash) && ! defaults.empty?
      defaults = symbol_map(defaults)
    end
    
    case data
    when Coral::Config
      @options = Util::Data.merge([ defaults, data.options ], force)
    when Hash
      @options = {}
      if data.is_a?(Hash)
        @options = Util::Data.merge([ defaults, symbol_map(data) ], force)
      end  
    end
  end
  
  #---
  
  def import(data, options = {})
    config = Config.new(options, { :force => @force }).set(:context, :hash)
    
    case data
    when Hash
      @options = Util::Data.merge([ @options, symbol_map(data) ], config)
    
    when String      
      data = lookup(data, {}, config)
      Util::Data.merge([ @options, data ], config)
     
    when Array
      data.each do |item|
        import(item, config)
      end
    end
    
    return self
  end
  
  #---
  
  def set(name, value)
    @options[name.to_sym] = value
    return self
  end
  
  def []=(name, value)
    set(name, value)
  end
  
  #---
    
  def get(name, default = nil)
    name = name.to_sym
    return @options[name] if @options.has_key?(name)
    return default
  end
  
  def [](name, default = nil)
    get(name, default)
  end
  
  #---
  
  def rm(name, default = nil)
    name = name.to_sym
    if @options.has_key(name)
      value = @options[name]
      @options.delete(name)
      return value
    end
    return default
  end
  
  #---
  
  def options
    return @options
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.symbol_map(data)
    results = {}
    data.each do |key, value|
      if value.is_a?(Hash)
        results[key.to_sym] = symbol_map(value)  
      else
        results[key.to_sym] = value  
      end      
    end
    return results  
  end
  
  #---
  
  def symbol_map(data)
    return self.class.symbol_map(data)
  end
  protected :symbol_map
end
end