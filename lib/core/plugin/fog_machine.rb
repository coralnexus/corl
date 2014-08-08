
nucleon_require(File.dirname(__FILE__), :machine)

#---

module CORL
module Machine
class Fog < Nucleon.plugin_class(:CORL, :machine)
  
  include Mixin::Machine::SSH

  #-----------------------------------------------------------------------------
  # Machine plugin interface
  
  def normalize(reload)
    super
    myself.plugin_name = '' if myself.plugin_provider == myself.plugin_name.to_sym
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
    translate_state(:aborted)
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
  
  def create(options = {}, &code)
    super do |config|
      if compute
        code.call(config) if code
        myself.server = compute.servers.bootstrap(config.export)
      end
      myself.server ? true : false
    end
  end
  
  #---
  
  def download(remote_path, local_path, options = {}, &code)
    super do |config, success|
      ssh_download(remote_path, local_path, config, &code)
    end  
  end
  
  #---
  
  def upload(local_path, remote_path, options = {}, &code)
    super do |config, success|
      ssh_upload(local_path, remote_path, config, &code)
    end  
  end
  
  #---
  
  def exec(commands, options = {}, &code)
    super do |config|
      ssh_exec(commands, config, &code)
    end
  end
  
  #---
  
  def terminal(user, options = {})
    super do |config|
      ssh_terminal(user, config)
    end
  end
  
  #---
  
  def reload(options = {}, &code)
    super do |config|
      success = code ? code.call(config) : true            
      success = init_ssh_session(true, config.get(:tries, 12), config.get(:sleep_time, 5)) if success
    end
  end

  #---
 
  def create_image(options = {}, &code)
    super do |config|
      image_name = sprintf("%s (%s)", node.plugin_name, Time.now.to_s)
      
      success = code ? code.call(image_name, config, success) : true 
      success = init_ssh_session(true, config.get(:tries, 12), config.get(:sleep_time, 5)) if success
    end
  end
  
  #---
  
  def stop(options = {})
    super do |config|
      success = false            
      success = destroy(config.import({ :stop => true })) if create_image(config)
    end
  end
  
  #---

  def destroy(options = {}, &code)
    super do |config|
      success = server.destroy
      success = code.call(config) if success && code
      
      close_ssh_session if success
      success
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def ssh_wait_for_ready
    server.wait_for { ready? }
  end
end
end
end