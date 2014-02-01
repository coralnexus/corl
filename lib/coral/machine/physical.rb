
module Coral
module Machine
class Physical < Plugin::Machine
  
  #-----------------------------------------------------------------------------
  # Machine plugin interface
  
  def normalize
    super
  end
     
  #-----------------------------------------------------------------------------
  # Checks
  
  def created?
    return true
  end
  
  #---
  
  def running?
    return true
  end
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def state
    return translate_state('RUNNING')
  end
  
  #-----------------------------------------------------------------------------
  # Management

  def create(options = {})
    return super do
      logger.warn("Damn!  We can't yet create new instances of physical machines")
      true
    end
  end
  
  #---
  
  def start(options = {})
    return super do
      logger.warn("This machine is already running so can not be started")
      true
    end
  end
  
  #---
  
  def stop(options = {})
    return super do
      logger.warn("Stopping the machine we are operating is not supported right now")
      true
    end
  end
  
  #---
  
  def reload(options = {})
    return super do
      logger.warn("Reloading not currently supported on physical machines")
      true
    end
  end

  #---

  def destroy(options = {})
    return super do
      logger.warn("If you want to destroy your physical machine, grab a hammer")
      true  
    end
  end
  
  #---
  
  def exec(options = {})
    return super do |config|
      success = true
      if commands = config.delete(:commands)
        commands.each do |command|
          success = Util::Shell.exec!(command.to_s, config) do |line|
            yield(line) if block_given?
          end
          break unless success
        end
      end
      success
    end
  end
  
  #---
 
  def create_image(name, options = {})
    return super do
      logger.warn("Creating images of local machines not supported yet")
      true
    end
  end
end
end
end