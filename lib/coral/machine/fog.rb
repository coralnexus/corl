
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
    return server && ! server.state != 'DELETED'
  end
  
  #---
  
  def running?
    return created? && server.ready?
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
    return @compute
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
    return @server
  end
  
  #---
  
  def state
    return translate_state(server.state) if server
    return nil
  end
  
  #---
  
  def flavors
    return compute.flavors if compute
    return nil
  end
  
  #---
  
  def flavor=flavor
    set(:flavor, flavor)
  end
  
  def flavor
    return get(:flavor, nil)
  end
  
  #---
  
  def images
    return compute.images if compute
    return nil
  end
  
  #---
  
  def image=image
    set(:image, image)
  end
  
  def image
    return get(:image, nil)
  end
  
  #-----------------------------------------------------------------------------
  # Management

  def create(options = {})
    return super do
      self.server = compute.servers.bootstrap(options)
      self.server ? true : false
    end
  end
  
  #---
  
  def start(options = {})
    return super do
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
    return super do
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
    return super do
      logger.debug("Rebooting machine #{name}")
      server.reboot(options)  
    end
  end

  #---

  def destroy(options = {})
    return super do
      logger.debug("Destroying machine #{name}")   
      server.destroy(options)  
    end
  end
  
  #---
  
  def exec(options = {})
    return super do
      success = true
      if commands = options.delete(:commands)
        logger.debug("Executing SSH commands ( #{commands.inspect} ) on machine #{name}") 
        success = server.ssh(commands, options)
      end
      success
    end
  end
  
  #---
 
  def create_image(name, options = {})
    return super do
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