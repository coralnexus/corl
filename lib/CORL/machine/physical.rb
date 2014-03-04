
module CORL
module Machine
class Physical < CORL.plugin_class(:machine)
  
  #-----------------------------------------------------------------------------
  # Machine plugin interface
  
  def normalize(reload)
    super
    myself.plugin_name = hostname
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
    CORL.ip_address
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
  
  def exec(commands, options = {}, &code)
    super do |config, results|
      logger.debug("Executing shell commands ( #{commands.inspect} ) on machine #{plugin_name}")
      
      commands.each do |command|
        result = CORL.cli_run(command, config) do |op, command_str, data|
          code ? code.call(op, command_str, data) : true
        end        
        results << result
      end
      results
    end
  end
 
  #---
  
  def terminal(user, options = {})
    super do |config|
      logger.debug("Launching terminals on the local machine is not currently supported")
      1
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