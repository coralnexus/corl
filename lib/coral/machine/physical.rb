
module Coral
module Machine
class Physical < Plugin::Machine
  
  #-----------------------------------------------------------------------------
  # Machine plugin interface
  
  def normalize
    super
    self.name = hostname
  end
     
  #-----------------------------------------------------------------------------
  # Checks
  
  def created?
    true
  end
  
  #---
  
  def running?
    true
  end
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
    
  def public_ip
    fact(:ipaddress)
  end

  #---
  
  def private_ip
    nil
  end

  #---
 
  def hostname
    fact(:hostname)
  end
 
  #---
 
  def state
    translate_state('RUNNING')
  end
  
  #-----------------------------------------------------------------------------
  # Management

  def create(options = {})
    super do
      logger.warn("Damn!  We can't yet create new instances of physical machines")
      true
    end
  end
  
  #---
  
  def start(options = {})
    super do
      logger.warn("This machine is already running so can not be started")
      true
    end
  end
  
  #---
  
  def stop(options = {})
    super do
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
    super do
      logger.warn("If you want to destroy your physical machine, grab a hammer")
      true  
    end
  end
  
  #---
  
  def exec(commands, options = {})
    super do |config, results|
      commands.each do |command|
        result = Util::Shell.exec!(command.to_s, config)
        results << { :status => result[:status], :result => result[:output], :error => result[:errors] }
      end
      results
    end
  end
  
  #---
 
  def create_image(name, options = {})
    super do
      logger.warn("Creating images of local machines not supported yet")
      true
    end
  end
end
end
end