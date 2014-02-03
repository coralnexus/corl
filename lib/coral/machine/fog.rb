
module Coral
module Machine
class Fog < Plugin::Machine
  
  #-----------------------------------------------------------------------------
  # Machine plugin interface
  
  def normalize
    super
    set_connection
  end
     
  #-----------------------------------------------------------------------------
  # Checks
  
  def created?
    server && ! server.state != 'DELETED'
  end
  
  #---
  
  def running?
    created? && server.ready?
  end
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def set_connection
    logger.info("Initializing Fog Compute connection to cloud hosting provider")
    logger.debug("Compute settings: #{export.inspect}")
    
    ENV['DEBUG'] = 'true' if Coral.log_level == :debug
    require 'fog'    
    
    self.compute = Fog::Compute.new(export)
    self.server  = name if @compute && name    
  end
  protected :set_connection
  
  #---
  
  def compute=compute
    @compute = compute
  end
  
  def compute
    set_connection unless @compute
    @compute
  end
  
  #---
  
  def server=id
    if id.is_a?(String)
      @server = compute.servers.get(id)
    else
      @server = id
    end
    
    self.name       = server.id
    self.hostname   = server.name
    self.image      = server.image
    self.flavor     = server.flavor
    
    self.public_ip  = server.public_ip_address
    self.private_ip = server.private_ip_address
  end
  
  def server
    @server
  end
  
  #---
  
  def state
    return translate_state(server.state) if server
    nil
  end
  
  #-----------------------------------------------------------------------------
  # Management

  def create(options = {})
    super do
      self.server = compute.servers.bootstrap(Config.ensure(options).export)
      self.server ? true : false
    end
  end
  
  #---
  
  def start(options = {})
    super do
      server_info = compute.servers.create(options)
      
      logger.info("Waiting for #{plugin_provider} machine to start")
      Fog.wait_for do
        compute.servers.get(server_info.id).ready? ? true : false
      end
      
      logger.debug("Setting machine #{server_info.id}")
            
      self.server = compute.servers.get(server_info.id)
      self.server ? true : false
    end
  end
  
  #---
  
  def stop(options = {})
    super do
      success = true
      if image_id = create_image(name)      
        logger.info("Waiting for #{plugin_provider} machine to finish creating image: #{image_id}")
        Fog.wait_for do
          compute.images.get(image_id).ready? ? true : false
        end
              
        logger.debug("Detroying machine #{name}")
        success = server.destroy        
      end
      success
    end
  end
  
  #---
  
  def reload(options = {})
    super do
      logger.debug("Rebooting machine #{name}")
      server.reboot(options)  
    end
  end

  #---

  def destroy(options = {})
    super do
      logger.debug("Destroying machine #{name}")   
      server.destroy(options)  
    end
  end
  
  #---
  
  def exec(options = {})
    super do
      success = true
      config  = Config.ensure(options)
      if commands = config.delete(:commands)
        logger.debug("Executing SSH commands ( #{commands.inspect} ) on machine #{name}") 
        success = server.ssh(commands, config.export)
      end
      success
    end
  end
  
  #---
 
  def create_image(name, options = {})
    super do
      logger.debug("Imaging machine #{self.name}") 
      image = server.create_image(name, options)
      
      if image
        self.image = image.id
        true
      else
        false
      end
    end
  end
end
end
end