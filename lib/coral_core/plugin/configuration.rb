
module Coral
module Plugin
class Configuration < Base
    
  include Mixin::SubConfig

  #-----------------------------------------------------------------------------
  # Configuration plugin interface
  
  def normalize
    super
    
    logger.debug("Initializing source sub configuration")
    init_subconfig(true)
    
    _init(:autoload, true)
    _init(:autosave, true)
  end
   
  #-----------------------------------------------------------------------------
  # Checks
  
  def can_persist?
    return false
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def autoload(default = false)
    return _get(:autoload, default)
  end
  
  def autoload=autoload
    _set(:autoload, test(autoload))
  end
   
  #---
  
  def autosave(default = false)
    return _get(:autosave, default)
  end
  
  def autosave=autosave
    _set(:autosave, test(autosave))
  end
  
  #-----------------------------------------------------------------------------
    
  def set(keys, value = '', options = {})
    super(keys, value)
    save(options) if autosave
    return self
  end
   
  #---
   
  def delete(keys, options = {})
    super(keys)
    save(options) if autosave
    return self
  end
  
  #---
  
  def clear(options = {})
    super
    save(options) if autosave
    return self
  end

  #-----------------------------------------------------------------------------
  # Import / Export
  
  def import(properties, options = {})
    super(properties, options)
    save(options) if autosave
    return self
  end
      
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load(options = {})
    method_config = Config.ensure(options)
    
    if can_persist? 
      if extension_check(:load, { :config => method_config })
        logger.info("Loading source configuration")
      
        config.clear if method_config.get(:override, false)
      
        properties = {}
        properties = yield(method_config, properties) if block_given?
          
        if properties && ! properties.empty?
          logger.debug("Source configuration parsed properties: #{properties}")
        
          extension(:load_process, { :properties => properties, :config => method_config })               
          config.import(properties, method_config)
        end
      end
    else
      logger.warn("Loading of source configuration from #{location} failed")
    end
    return self
  end
   
  #---
    
  def save(options = {})
    method_config = Config.ensure(options)
    
    if can_persist?
      if extension_check(:save, { :config => method_config })
        logger.info("Saving source configuration")
        logger.debug("Source configuration properties: #{config.export}") 
      
        yield(method_config) if block_given?
      end
    else
      logger.warn("Can not save source configuration")
    end
    return self
  end
  
  #---
  
  def delete(options = {})
    method_config = Config.ensure(options)
    
    if can_persist?
      if extension_check(:delete, { :config => method_config })
        logger.info("Removing source configuration")
      
        config.clear
      
        yield(method_config) if block_given?
      end
    else
      logger.warn("Can not delete source configuration")
    end
    return self 
  end
end
end
end
