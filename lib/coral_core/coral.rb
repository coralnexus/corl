
module Coral
 
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', '..', 'VERSION'))
  
  #-----------------------------------------------------------------------------
  
  def self.ui
    return Core.ui
  end
  
  #---
  
  def self.logger
    return Core.logger
  end
  
  #---
  
  def self.log_level
    return ENV['CORAL_LOG'].downcase.to_sym if ENV['CORAL_LOG']
    :none
  end
   
  #-----------------------------------------------------------------------------

  @@config_file = 'coral.json'
  
  #---
    
  def self.config_file=file_name
    @@config_file = file_name
  end
  
  #---
  
  def self.config_file
    return @@config_file
  end
  
  #-----------------------------------------------------------------------------
  
  def self.admin?
    is_admin  = ( ENV['USER'] == 'root' )
    ext_admin = exec!(:check_admin) do |op, results|
      if op == :reduce
        results.values.include?(true)
      else
        results ? true : false
      end
    end
    is_admin || ext_admin ? true : false
  end
  
  #-----------------------------------------------------------------------------
  # Status codes
  
  @@codes = Codes.new
  
  def self.code
    @@codes
  end
  
  def self.codes(*codes)
    Codes.codes(*codes)
  end

  #-----------------------------------------------------------------------------
  # Initialization
  
  @@initialized = false
  
  def self.initialize
    unless @@initialized
      current_time = Time.now
      
      logger.info("Initializing the Coral plugin system at #{current_time}")
      Config.set_property('time', current_time.to_i)
      
      Plugin.initialize do
        begin
          logger.info("Registering Coral plugin defined within Puppet modules")
          
          # Include Coral plugins
          #Puppet::Node::Environment.new.modules.each do |mod|
          #  lib_path = File.join(mod.path, 'lib', 'coral')
            
          #  logger.debug("Registering Puppet module at #{lib_path}")
          #  Plugin.register(lib_path)
          #end
        rescue
        end
        
        logger.info("Finished initializing Coral plugin system at #{Time.now}")
      end
            
      @@initialized = true
    end    
  end
  
  #---
  
  def self.initialized?
    return @@initialized
  end
  
  #-----------------------------------------------------------------------------
  # Core plugin interface
  
  def self.plugin_load(type, provider, options = {})
    config = Config.ensure(options)
    name   = config.get(:name, nil)
    
    logger.info("Fetching plugin #{type} provider #{provider} at #{Time.now}")
    logger.debug("Plugin options: #{config.export.inspect}")
    
    if name
      logger.debug("Looking up existing instance of #{name}")
      
      existing_instance = Plugin.get_instance(type, name)
      logger.info("Using existing instance of #{type}, #{name}") if existing_instance
    end
    
    return existing_instance if existing_instance
    return Plugin.create_instance(type, provider, config.export)  
  end
  
  #---
  
  def self.plugin(type, provider, options = {})
    default_provider = Plugin.type_default(type)
    
    if options.is_a?(Hash) || options.is_a?(Coral::Config)
      config   = Config.ensure(options)
      provider = config.get(:provider, provider)
      options  = config.export
    end
    provider = default_provider unless provider # Sanity checking (see plugins)
    
    return plugin_load(type, provider, options)
  end
  
  #---
  
  def self.plugins(type, data, build_hash = false, keep_array = false)
    logger.info("Fetching multiple plugins of #{type} at #{Time.now}")
    
    group = ( build_hash ? {} : [] )
    klass = class_const([ :coral, :plugin, type ])    
    data  = klass.build_info(type, data) if klass.respond_to?(:build_info)
    
    logger.debug("Translated plugin data: #{data.inspect}")
    
    data.each do |options|
      if plugin = plugin(type, options[:provider], options)
        if build_hash
          group[plugin.name] = plugin
        else
          group << plugin
        end
      end
    end
    return group.shift if ! build_hash && group.length == 1 && ! keep_array
    return group  
  end
  
  #---
  
  def self.get_plugin(type, name)
    return Plugin.get_instance(type, name)
  end
  
  #---
  
  def self.remove_plugin(plugin)
    return Plugin.remove_instance(plugin)
  end

  #-----------------------------------------------------------------------------
  # Plugin extensions
   
  def self.exec!(method, options = {})
    return Plugin.exec!(method, options) do |op, results|
      results = yield(op, results) if block_given?
      results
    end
  end
  
  #---
  
  def self.config(type, options = {})
    config = Config.ensure(options)
    
    logger.debug("Generating #{type} extended configuration from: #{config.export.inspect}")
      
    exec!("#{type}_config", Config.new(config.export).import({ :extension_type => :config })) do |op, results|
      if op == :reduce
        results.each do |provider, result|
          config.defaults(result)
        end
        nil
      else
        hash(results)
      end
    end    
    config.delete(:extension_type)
     
    logger.debug("Final extended configuration: #{config.export.inspect}")   
    config 
  end
  
  #---
  
  def self.check(method, options = {})
    config = Config.ensure(options)
    
    logger.debug("Checking extension #{method} given: #{config.export.inspect}")
    
    success = exec!(method, config.import({ :extension_type => :check })) do |op, results|
      if op == :reduce
        ! results.values.include?(false)
      else
        results ? true : false
      end
    end
    
    success = success.nil? || success ? true : false
    
    logger.debug("Extension #{method} check result: #{success.inspect}")      
    success
  end
  
  #---
  
  def self.value(method, value, options = {})
    config = Config.ensure(options)
    
    logger.debug("Setting extension #{method} value given: #{value.inspect}")
    
    exec!(method, config.import({ :value => value, :extension_type => :value })) do |op, results|
      if op == :process
        value = results unless results.nil?  
      end
    end
    
    logger.debug("Extension #{method} retrieved value: #{value.inspect}")
    value
  end
       
  #-----------------------------------------------------------------------------
  # External execution
   
  def self.run
    begin
      logger.debug("Running contained process at #{Time.now}")
      
      initialize
      yield
      
    rescue Exception => error
      logger.error("Coral run experienced an error! Details:")
      logger.error(error.inspect)
      logger.error(error.message)
      logger.error(Util::Data.to_yaml(error.backtrace))
  
      ui.error(error.message) if error.message
      raise
    end
  end
  
  #---
  
  @@batch_lock = Mutex.new
  
  def self.batch(parallel = true)
    result = nil
    
    @@batch_lock.synchronize do
      begin
        logger.debug("Running contained process at #{Time.now}")
        
        Util::Batch.new(parallel) do |batch|
          yield(:add, batch)          
          result = yield(:reduce, batch.run)
        end        
        
      rescue Exception => error
        logger.error("Coral batch experienced an error:")
        logger.error(error.inspect)
        logger.error(error.message)
        logger.error(Util::Data.to_yaml(error.backtrace))
  
        ui.error(error.message) if error.message
      end      
    end
    
    result
  end
    
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.class_name(name, separator = '::', want_array = FALSE)
    components = []
    
    case name
    when String, Symbol
      components = name.to_s.split(separator)
    when Array
      components = name 
    end
    
    components.collect! do |value|
      value.to_s.strip.capitalize  
    end
    
    if want_array
      return components
    end    
    return components.join(separator)
  end
  
  #---
  
  def self.class_const(name, separator = '::')
    components = class_name(name, separator, TRUE)
    constant   = Object
    
    components.each do |component|
      constant = constant.const_defined?(component) ? 
                  constant.const_get(component) : 
                  constant.const_missing(component)
    end
    
    return constant
  end
  
  #---
  
  def self.sha1(data)
    return Digest::SHA1.hexdigest(Util::Data.to_json(data, false))
  end  
end
