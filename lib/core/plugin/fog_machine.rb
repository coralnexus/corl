
nucleon_require(File.dirname(__FILE__), :machine)

#---

module CORL
module Machine
class Fog < CORL.plugin_class(:machine)
 
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
    
    ENV['DEBUG'] = 'true' if CORL.log_level == :debug
    
    require 'fog'
            
    myself.compute = ::Fog::Compute.new(export)
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
    @server = nil
    
    if id.is_a?(String)
      @server = compute.servers.get(id) unless id.empty?
    elsif ! id.nil?
      @server = id
    end    
    init_server
  end
  
  def server
    compute
    load unless @server
    @server
  end
   
  #---
  
  def state
    return translate_state(server.state) if server
    nil
  end
   
  #---
  
  def public_ip
    return server.public_ip_address if server
    nil
  end
  
  #---
  
  def private_ip
    return server.private_ip_address if server
    nil
  end
  
  #---
    
  def machine_types
    return compute.flavors if compute
    []
  end
  
  #---
  
  def machine_type
    return server.flavor.id if server
    nil
  end
  
  #---
  
  def images
    return compute.images if compute
    []
  end
  
  #---
  
  def image
    return server.image.id if server
    nil
  end
  
  #-----------------------------------------------------------------------------
  # Management
  
  def init_server
    unless @server.nil?
      yield # Implement in fog machine providers
    end  
  end
  protected :init_server
  
  #---
  
  def load
    super do
      myself.server = plugin_name if compute && plugin_name
      ! plugin_name && @server.nil? ? false : true
    end    
  end
  
  #---
  
  def create(options = {})
    super do |method_config|
      if compute
        yield(method_config) if block_given?
        myself.server = compute.servers.bootstrap(method_config.export)
      end
      myself.server ? true : false
    end
  end
  
  #---
  
  def download(remote_path, local_path, options = {})
    super do |config, success|
      logger.debug("Executing SCP download to #{local_path} from #{remote_path} on machine #{name}") 
      
      begin
        if init_ssh_session(server)
          Util::SSH.download(node.public_ip, node.user, remote_path, local_path, config.export) do |name, received, total|
            yield(name, received, total) if block_given?
          end
          true
        else
          false
        end
      rescue Exception => error
        ui.error(error.message)
        false
      end
    end  
  end
  
  #---
  
  def upload(local_path, remote_path, options = {})
    super do |config, success|
      logger.debug("Executing SCP upload from #{local_path} to #{remote_path} on machine #{plugin_name}") 
      
      begin
        if init_ssh_session(server)
          Util::SSH.upload(node.public_ip, node.user, local_path, remote_path, config.export) do |name, sent, total|
            yield(name, sent, total) if block_given?
          end
          true
        else
          false
        end
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
        logger.debug("Executing SSH commands ( #{commands.inspect} ) on machine #{plugin_name}")
        
        if init_ssh_session(server)
          results = Util::SSH.exec(node.public_ip, node.user, commands) do |type, command, data|
            yield(type, command, data) if block_given?  
          end
        else
          results = nil
        end
      end
      results
    end
  end
  
  #---
  
  def terminal(user, options = {})
    super do |config|
      Util::SSH.terminal(node.public_ip, user, config.export)
    end
  end
  
  #---
  
  def reload(options = {})
    super do |method_config|
      success = false
      if server
        success = block_given? ? yield(method_config) : true            
        success = init_ssh_session(server, true, method_config.get(:tries, 5), method_config.get(:sleep_time, 5)) if success
      end
      success
    end
  end

  #---
 
  def create_image(options = {})
    super do |method_config|
      success = false
      if server
        logger.debug("Imaging machine #{plugin_name}")
        image = server.create_image(sprintf(method_config.get(:image_name_format, "%s (%s)"), node.plugin_name, Time.now.to_s))        
        image.wait_for { ready? }
      
        if image
          node[:image] = image.id
          success      = true
        end
      end
      success
    end
  end
  
  #---
  
  def stop(options = {})
    super do
      success = true
      if server && create_image(options)      
        logger.debug("Stopping machine #{plugin_name}")
        success = server.destroy
      else
        success = false            
      end
      close_ssh_session if success
      success
    end
  end
  
  #---

  def destroy(options = {})
    super do
      success = false
      if server
        logger.debug("Destroying machine #{plugin_name}")
        success = server.destroy
      end
      close_ssh_session if success
      success
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def init_ssh_session(server, reset = false, tries = 5, sleep_secs = 5)
    server.wait_for { ready? }
    
    success = true
        
    begin
      Util::SSH.session(node.public_ip, node.user, node.ssh_port, node.private_key, reset)
            
    rescue Exception => error
      if tries > 1
        sleep(sleep_secs)
        
        tries -= 1
        reset  = true
        retry
      else
        success = false
      end
    end
    success
  end
  
  #---
  
  def close_ssh_session
    Util::SSH.close_session(node.public_ip, node.user)
  end
end
end
end