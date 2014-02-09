
module Coral
module Machine
class Fog < Plugin::Machine
  
  #-----------------------------------------------------------------------------
  # Machine plugin interface
  
  def normalize
    super
    
    self.private_key = delete(:private_key_path, nil)
    self.public_key  = delete(:public_key_path, nil)
    
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
  
  def download(remote_path, local_path, options = {})
    super do |config, success|
      require 'net/scp'
      
      ssh_options = {
        :port         => server.ssh_port,
        :keys         => [ private_key ],
        :key_data     => [],
        :auth_methods => [ 'publickey' ]
      } 
        
      logger.debug("Executing SCP download to #{local_path} from #{remote_path} on machine #{name}") 
      
      begin
        ::Fog::SCP.new(public_ip, server.username, ssh_options).download(remote_path, local_path, config.export)
        true
      rescue
        false
      end
    end  
  end
  
  #---
  
  def upload(local_path, remote_path, options = {})
    super do |config, success|
      require 'net/scp'
      
      config.defaults({ :recursive => true })
      
      ssh_options = {
        :port         => server.ssh_port,
        :keys         => [ private_key ],
        :key_data     => [],
        :auth_methods => [ 'publickey' ]
      } 
        
      logger.debug("Executing SCP upload from #{local_path} to #{remote_path} on machine #{name}") 
      
      begin
        ::Fog::SCP.new(public_ip, server.username, ssh_options).upload(local_path, remote_path, config.export)
        true
      rescue
        false
      end
    end  
  end
  
  #---
  
  def exec(commands, options = {})
    super do |config, results|
      require 'net/ssh'
      
      if commands
        ssh_options = {
          :port         => server.ssh_port,
          :keys         => [ private_key ],
          :key_data     => [],
          :keys_only    => false,
          :auth_methods => [ 'publickey' ]
        }
        
        logger.debug("Executing SSH commands ( #{commands.inspect} ) on machine #{name}") 
        
        begin
          Net::SSH.start(public_ip, server.username, ssh_options) do |ssh|
            commands.each do |command|
              result = Util::Shell::Result.new(command)
              
              ssh.open_channel do |ssh_channel|
                ssh_channel.request_pty
                ssh_channel.exec(command) do |channel, success|
                  unless success
                    raise "Could not execute command: #{command.inspect}"
                  end

                  channel.on_data do |ch, data|
                    result.append_output(data)
                    ui_group!(hostname) do
                      ui.info(data)
                    end
                  end

                  channel.on_extended_data do |ch, type, data|
                    next unless type == 1
                    result.append_errors(data)
                    ui_group!(hostname) do
                      ui.error(data)
                    end
                  end

                  channel.on_request('exit-status') do |ch, data|
                    result.status = data.read_long
                  end

                  channel.on_request('exit-signal') do |ch, data|
                    result.status = 255
                  end
                end
              end
              ssh.loop              
              results << result
            end
          end
        rescue Net::SSH::HostKeyMismatch => error
          error.remember_host!
          sleep 0.2
          retry
        end
      end
      results
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