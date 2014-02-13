
module Coral
module Machine
class Fog < Plugin::Machine
  
  #-----------------------------------------------------------------------------
  # Machine plugin interface
  
  def normalize
    super
    
    self.private_key = delete(:private_key_path, nil)
    self.public_key  = delete(:public_key_path, nil)
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
        
    compute_config = Config.new(export)
    compute_config.delete(:private_key)
    compute_config.delete(:public_key)   
    
    self.compute = ::Fog::Compute.new(compute_config.export)
    self.server  = name if @compute && ! name.empty?    
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
    
    server.private_key_path = private_key if private_key
    server.public_key_path  = public_key if public_key
    
    Util::SSH.init_session(public_ip, server.username, server.ssh_port, private_key)
  end
  
  def server
    @server
  end
  
  #---
  
  def state
    return translate_state(server.state) if server
    nil
  end
  
  #---
    
  def machine_types
    return compute.flavors if compute
    super
  end
  
  #---
  
  def images
    return compute.images if compute
    super
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
  
  def download(remote_path, local_path, options = {})
    super do |config, success|
      logger.debug("Executing SCP download to #{local_path} from #{remote_path} on machine #{name}") 
      
      begin
        Util::SSH.download!(public_ip, server.username, remote_path, local_path, config.export) do |name, received, total|
          yield(name, received, total) if block_given?
        end
        true
      rescue Exception => error
        ui.error(error.message)
        false
      end
    end  
  end
  
  #---
  
  def upload(local_path, remote_path, options = {})
    super do |config, success|
      logger.debug("Executing SCP upload from #{local_path} to #{remote_path} on machine #{name}") 
      
      begin
        Util::SSH.upload!(public_ip, server.username, local_path, remote_path, config.export) do |name, sent, total|
          yield(name, sent, total) if block_given?
        end
        true
      rescue Exception => error
        ui.error(error.message)
        false
      end
    end  
  end
  
  #---
  
  def exec(commands, options = {})
    super do |config, results|
      if commands
        logger.debug("Executing SSH commands ( #{commands.inspect} ) on machine #{name}")
        
        results = Util::SSH.exec!(public_ip, server.username, commands) do |type, command, data|
          yield(type, command, data) if block_given?  
        end
      end
      results
    end
  end
  
  #---
  
  def start(options = {})
    super do
      server_info = compute.servers.create(options)
      
      logger.info("Waiting for #{plugin_provider} machine to start")
      ::Fog.wait_for do
        compute.servers.get(server_info.id).ready? ? true : false
      end
      
      logger.debug("Setting machine #{server_info.id}")
            
      self.server = compute.servers.get(server_info.id)
      self.server ? true : false
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
  
  #---
  
  def stop(options = {})
    super do
      success = true
      if image_id = create_image(name)      
        logger.info("Waiting for #{plugin_provider} machine to finish creating image: #{image_id}")
        ::Fog.wait_for do
          compute.images.get(image_id).ready? ? true : false
        end
              
        logger.debug("Detroying machine #{name}")
        success = server.destroy        
      end
      success
    end
  end
  
  #---

  def destroy(options = {})
    super do
      logger.debug("Destroying machine #{name}")   
      server.destroy(options)  
    end
  end
end
end
end