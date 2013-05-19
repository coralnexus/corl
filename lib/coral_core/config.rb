
module Coral
class Config
  
  #-----------------------------------------------------------------------------
  # Global configuration
  
  @@options = {}
  
  #---
  
  def self.options(contexts, force = true)
    options = {}
    
    unless contexts.is_a?(Array)
      contexts = [ contexts ]
    end
    contexts.each do |name|
      if @@options.has_key?(name)
        options = Util::Data.merge([ options, @@options[name] ], force)
      end
    end
    return options
  end
  
  #---
  
  def self.set_options(context, options, force = true)    
    current_options = ( @@options.has_key?(context) ? @@options[context] : {} )
    @@options[context] = Util::Data.merge([ current_options, options ], force)  
  end
  
  #---
  
  def self.clear_options(contexts)
    unless contexts.is_a?(Array)
      contexts = [ contexts ]
    end
    contexts.each do |name|
      @@options.delete(name)
    end
  end
  
  #-----------------------------------------------------------------------------

  @@properties = {}
  
  #---
  
  def self.properties
    return @@properties
  end
  
  #---
  
  def self.set_property(name, value)
    #dbg(value, "result -> #{name}")
    @@properties[name] = value
    save_properties  
  end
  
  #---
  
  def self.clear_property(name)
    @@properties.delete(name)
    save_properties
  end
  
  #---
  
  def self.save_properties
    log_options = options('coral_log')
    
    unless Util::Data.empty?(log_options['config_log'])
      config_log = log_options['config_log']
      
      Util::Disk.write(config_log, JSON.pretty_generate(@@properties))
      Util::Disk.close(config_log)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Hiera configuration
  
  @@hiera = nil
  
  #---
  
  def self.hiera_config
    config_file = Puppet.settings[:hiera_config]
    config      = {}

    if File.exist?(config_file)
      config = Hiera::Config.load(config_file)
    else
      Coral.ui.warn("Config file #{config_file} not found, using Hiera defaults")
    end

    config[:logger] = 'puppet'
    return config
  end
  
  #---

  def self.hiera
    @@hiera = Hiera.new(:config => hiera_config) unless @@hiera
    return @@hiera
  end
  
  #---

  def hiera
    return self.class.hiera
  end
  
  #-----------------------------------------------------------------------------
  # Configuration lookup
      
  def self.initialized?(options = {})
    config = Config.ensure(options)
    begin
      require 'hiera_puppet'
      
      scope       = config.get(:scope, {})
      
      sep         = config.get(:sep, '::')
      prefix      = config.get(:prefix, true)    
      prefix_text = prefix ? sep : ''
      
      init_fact   = prefix_text + config.get(:init_fact, 'hiera_ready')
      coral_fact  = prefix_text + config.get(:coral_fact, 'coral_exists') 
      
      if Puppet::Parser::Functions.function('hiera')
        if scope.respond_to?('[]')
          return true if Util::Data.true?(scope[init_fact]) && Util::Data.true?(scope[coral_fact])
        else
          return true
        end
      end
    
    rescue Exception # Prevent abortions.
    end    
    return false
  end
  
  #---
    
  def self.lookup(name, default = nil, options = {})
    config = Config.ensure(options)
    value  = nil
    
    context     = config.get(:context, :priority)
    scope       = config.get(:scope, {})
    override    = config.get(:override, nil)
    
    base_names  = config.get(:search, nil)
    sep         = config.get(:sep, '::')
    prefix      = config.get(:prefix, true)    
    prefix_text = prefix ? sep : ''
    
    search_name    = config.get(:search_name, true)
    reverse_lookup = config.get(:reverse_lookup, true)
    
    #dbg(default, "lookup -> #{name}")
    
    if Config.initialized?(options)
      unless scope.respond_to?("[]")
        scope = Hiera::Scope.new(scope)
      end
      value = hiera.lookup(name, default, scope, override, context)
      #dbg(value, "hiera -> #{name}")
    end 
    
    if Util::Data.undef?(value) && ( scope.respond_to?("[]") || scope.respond_to?("lookupvar") )
      log_level = Puppet::Util::Log.level
      Puppet::Util::Log.level = :err # Don't want failed parameter lookup warnings here.
      
      if base_names
        if base_names.is_a?(String)
          base_names = [ base_names ]
        end
        base_names = base_names.reverse if reverse_lookup
        
        #bg(base_names, 'search path')        
        base_names.each do |item|
          if scope.respond_to?("lookupvar")
            value = scope.lookupvar("#{prefix_text}#{item}#{sep}#{name}")  
          else
            value = scope["#{prefix_text}#{item}#{sep}#{name}"]
          end
          #dbg(value, "#{prefix_text}#{item}#{sep}#{name}")
          break unless Util::Data.undef?(value)  
        end
      end
      if Util::Data.undef?(value) && search_name
        if scope.respond_to?("lookupvar")
          value = scope.lookupvar("#{prefix_text}#{name}")
        else
          value = scope["#{prefix_text}#{name}"]
        end
        #dbg(value, "#{prefix_text}#{name}")
      end
      Puppet::Util::Log.level = log_level
    end    
    value = default if Util::Data.undef?(value)
    value = Util::Data.value(value)
    
    if ! @@properties.has_key?(name) || ! Util::Data.undef?(value)
      set_property(name, value)
    end
    
    #dbg(value, "result -> #{name}")    
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
      results = Config.lookup(data.to_s, {}, config)
      
    when Array
      data.each do |item|
        if item.is_a?(String) || item.is_a?(Symbol)
          item = Config.lookup(item.to_s, {}, config)
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
  # Instance generators
  
  def self.ensure(config)
    case config
    when Coral::Config
      return config
    when Hash
      return Config.new(config) 
    end
    return Config.new
  end
  
  #---
  
  def self.init(options, contexts = [], defaults = {})
    config = Coral::Config.new(Coral::Config.options(contexts), defaults)
    config.import(options) unless Coral::Util::Data.empty?(options)
    return config
  end
  
  #-----------------------------------------------------------------------------
  # Configuration instance
    
  def initialize(data = {}, defaults = {}, force = true)
    @force   = force
    @options = {}
    
    if defaults.is_a?(Hash) && ! defaults.empty?
      symbolized = {}
      defaults.each do |key, value|
        symbolized[key.to_sym] = value
      end
      defaults = symbolized
    end
    
    case data
    when Coral::Config
      @options = Util::Data.merge([ defaults, data.options ], force)
    when Hash
      @options = {}
      if data.is_a?(Hash)
        symbolized = {}
        data.each do |key, value|
          symbolized[key.to_sym] = value
        end
        @options = Util::Data.merge([ defaults, symbolized ], force)
      end  
    end
  end
  
  #---
  
  def import(data, options = {})
    config = Config.new(options, { :force => @force }).set(:context, :hash)
    
    case data
    when Hash
      symbolized = {}
      data.each do |key, value|
        symbolized[key.to_sym] = value
      end
      @options = Util::Data.merge([ @options, symbolized ], config)
    
    when String      
      data = Util::Data.lookup(data, {}, config)
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
  
  def options
    return @options
  end
end
end