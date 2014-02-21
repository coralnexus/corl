
module Nucleon
module Plugin
class Configuration < plugin_class(:base)
    
  include Mixin::SubConfig

  #-----------------------------------------------------------------------------
  # Configuration plugin interface
  
  def normalize
    super
    
    logger.debug("Initializing source sub configuration")
    init_subconfig(true)
    
    _init(:autoload, true)
    _init(:autosave, false)
  end
   
  #-----------------------------------------------------------------------------
  # Checks
  
  def can_persist?
    false
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def autoload(default = false)
    _get(:autoload, default)
  end
  
  def autoload=autoload
    _set(:autoload, test(autoload))
  end
   
  #---
  
  def autosave(default = false)
    _get(:autosave, default)
  end
  
  def autosave=autosave
    _set(:autosave, test(autosave))
  end
  
  #-----------------------------------------------------------------------------
    
  def set(keys, value = '', options = {})
    super(keys, value)
    save(options) if autosave
  end
   
  #---
   
  def delete(keys, options = {})
    super(keys)
    save(options) if autosave
  end
  
  #---
  
  def clear(options = {})
    super
    save(options) if autosave
  end
  
  #-----------------------------------------------------------------------------
  
  def remote(name)
    nil
  end

  #---
  
  def set_remote(name, location)
  end
  
  #-----------------------------------------------------------------------------
  # Import / Export
  
  def import(properties, options = {})
    super(properties, options)
    save(options) if autosave
  end
      
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    method_config = Config.ensure(options)
    success = false
    
    if can_persist?
      if extension_check(:load, { :config => method_config })
        logger.info("Loading source configuration")
      
        config.clear if method_config.get(:override, false)
      
        properties = Config.new
        yield(method_config, properties) if block_given?
          
        unless properties.export.empty?
          logger.debug("Source configuration parsed properties: #{properties}")
        
          extension(:load_process, { :properties => properties, :config => method_config })               
          config.import(properties, method_config)
        end
        success = true
      end
    else
      logger.warn("Loading of source configuration failed")
    end
    success
  end
   
  #---
    
  def save(options = {})
    method_config = Config.ensure(options)
    success       = false
    
    if can_persist?
      if extension_check(:save, { :config => method_config })
        logger.info("Saving source configuration")
        logger.debug("Source configuration properties: #{config.export}") 
      
        success = yield(method_config) if block_given?
      end
    else
      logger.warn("Can not save source configuration")
    end
    success
  end
  
  #---
  
  def remove(options = {})
    method_config = Config.ensure(options)
    success       = false
    
    if can_persist?
      if extension_check(:delete, { :config => method_config })
        logger.info("Removing source configuration")
      
        config.clear
      
        success = yield(method_config) if block_given?
      end
    else
      logger.warn("Can not remove source configuration")
    end
    success
  end
  
  #---
  
  def attach(type, name, data, options = {})
    method_config = Config.ensure(options)
    new_location  = nil
    
    if can_persist?
      if extension_check(:attach, { :config => method_config })
        logger.info("Attaching data to source configuration")
      
        new_location = yield(method_config) if block_given?
      end
    else
      logger.warn("Can not attach data to source configuration")
    end
    new_location
  end
end
end
end
