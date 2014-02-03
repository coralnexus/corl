
module Coral
module Plugin
class Machine < Base

  #-----------------------------------------------------------------------------
  # Machine plugin interface
 
      
  #-----------------------------------------------------------------------------
  # Checks
  
  def created?
    false
  end
  
  #---
  
  def running?
    ( created? && false )
  end
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def hostname=hostname
    set(:hostname, hostname)
  end
  
  def hostname
    get(:hostname, '')
  end
  
  #---
  
  def state
    nil
  end
  
  #---
  
  def public_ip=public_ip
    set(:public_ip, public_ip)
  end
  
  def public_ip
    get(:public_ip, nil)
  end
  
  #---
  
  def private_ip=private_ip
    set(:private_ip, private_ip)
  end
  
  def private_ip
    get(:private_ip, nil)
  end
  
  #---
    
  def machine_types
    []
  end
  
  #---
  
  def images
    []
  end
            
  #-----------------------------------------------------------------------------
  # Management 

  def create(options = {})
    success = true
    
    if created?
      logger.debug("Machine #{name} already exists")
    else
      logger.debug("Creating #{plugin_provider} machine with: #{options.inspect}")
      config  = Config.ensure(options)
      success = yield(config) if block_given?  
    end
    
    logger.warn("There was an error creating the machine #{name}") unless success
    success
  end
  
  #---
  
  def start(options = {})
    success = true
    
    if running?
      logger.debug("Machine #{name} is already running")  
    else
      logger.debug("Starting #{plugin_provider} machine with: #{options.inspect}")
      
      if created?
        config  = Config.ensure(options)
        success = yield(config) if block_given?    
      else
        logger.debug("Machine #{name} does not yet exist")
        success = create(options)
      end      
    end
    
    logger.warn("There was an error starting the machine #{name}") unless success
    success
  end
  
  #---
  
  def stop(options = {})
    success = true
    
    if running?
      logger.debug("Stopping #{plugin_provider} machine with: #{options.inspect}")
      config  = Config.ensure(options)      
      success = yield(config) if block_given?
    else
      logger.debug("Machine #{name} is not running")  
    end
    
    logger.warn("There was an error stopping the machine #{name}") unless success
    success
  end
  
  #---
  
  def reload(options = {})
    success = true
    
    if created?
      logger.debug("Reloading #{plugin_provider} machine with: #{options.inspect}")
      config  = Config.ensure(options)
      success = yield(config) if block_given?
    else
      logger.debug("Machine #{name} does not yet exist")
    end
    
    logger.warn("There was an error reloading the machine #{name}") unless success
    success
  end

  #---

  def destroy(options = {})   
    success = true
    
    if created?
      logger.debug("Destroying #{plugin_provider} machine with: #{options.inspect}")
      config  = Config.ensure(options)
      success = yield(config) if block_given?
    else
      logger.debug("Machine #{name} does not yet exist")
    end
    
    logger.warn("There was an error destroying the machine #{name}") unless success
    success
  end
  
  #---
  
  def exec(options = {})
    success = true
    
    if running?
      logger.debug("Executing command on #{plugin_provider} machine with: #{options.inspect}")
      config  = Config.ensure(options)      
      success = yield(config) if block_given?
    else
      logger.debug("Machine #{name} is not running")  
    end
    
    logger.warn("There was an error executing command on the machine #{name}") unless success
    success
  end
  
  #---
  
  def create_image(options = {})
    success = true
    
    if running?
      logger.debug("Creating image of #{plugin_provider} machine with: #{options.inspect}")
      config  = Config.ensure(options)      
      success = yield(config) if block_given?
    else
      logger.debug("Machine #{name} is not running")  
    end
    
    logger.warn("There was an error creating an image of the machine #{name}") unless success
    success
  end

  #-----------------------------------------------------------------------------
  # Utilities

  def translate_state(state)
    return string(state).downcase.to_sym if status
    :unknown
  end
end
end
end