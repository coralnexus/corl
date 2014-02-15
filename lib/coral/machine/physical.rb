
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
  
  def state
    translate_state('RUNNING')
  end
  
  #---
  
  def hostname
    fact(:hostname)
  end
  
  #---
  
  def public_ip
    fact(:ipaddress)
  end
  
  #---
  
  def private_ip
    nil
  end
  
  #---
  
  def machine_type
    'physical'
  end
  
  #---
  
  def image
    nil
  end
  
  #-----------------------------------------------------------------------------
  # Management

  def load
    super do
      true
    end    
  end
  
  #---
  
  def create(options = {})
    super do
      logger.warn("Damn!  We can't create new instances of physical machines")
      true
    end
  end
  
  #---
  
  def download(remote_path, local_path, options = {})
    super do |config, success|
      logger.debug("Executing SCP downloads not yet supported on physical machines")
      true
    end
  end
  
  #---
  
  def upload(local_path, remote_path, options = {})
    super do |config, success|
      logger.debug("Executing SCP uploads not yet supported on physical machines")
      true
    end
  end
  
  #---
  
  def exec(commands, options = {})
    super do |config, results|
      logger.debug("Executing shell commands ( #{commands.inspect} ) on machine #{name}")
      
      commands.each do |command|
        result = Util::Shell.exec(command, config) do |type, command_str, data|
          yield(type, command_str, data) if block_given?   
        end        
        results << result
      end
      results
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
  
  def reload(options = {})
    return super do
      logger.warn("Reloading not currently supported on physical machines")
      true
    end
  end
 
  #---
 
  def create_image(name, options = {})
    super do
      logger.warn("Creating images of local machines not supported yet")
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

  def destroy(options = {})
    super do
      logger.warn("If you want to destroy your physical machine, grab a hammer")
      true  
    end
  end
end
end
end