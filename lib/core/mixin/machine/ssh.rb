module CORL
module Mixin
module Machine
module SSH

  #-----------------------------------------------------------------------------
  # SSH Operations
       
  def init_ssh_session(reset = false, tries = 12, sleep_secs = 5)
    ssh_wait_for_ready
    
    success     = true
    
    public_ip   = node.public_ip
    user        = node.user
    ssh_port    = node.ssh_port
    private_key = node.private_key
    
    ssh_config  = Config.new({ 
      :keypair  => node.keypair,
      :key_dir  => node.network.key_cache_directory,
      :key_name => node.plugin_name 
    })
    
    begin
      Util::SSH.session(public_ip, user, ssh_port, private_key, reset, ssh_config)
      node.keypair = ssh_config[:keypair]
            
    rescue Net::SSH::HostKeyMismatch => error
      error.remember_host!
      sleep 0.2
      reset = true
      retry

    rescue Errno::ECONNREFUSED, Net::SSH::ConnectionTimeout, Net::SSH::Disconnect => error     
      if tries > 1
        sleep(sleep_secs)
        
        tries -= 1
        reset  = true
        retry
      else
        success = false
      end
      
    rescue => error
      warn(error, { :i18n => false })
      success = false
    end
    success
  end
  
  #---
  
  def ssh_download(remote_path, local_path, options = {}, &code)
    config  = Config.ensure(options)
    success = false
    
    begin
      if init_ssh_session
        Util::SSH.download(node.public_ip, node.user, remote_path, local_path, config.export) do |name, received, total|
          code.call(name, received, total) if code
        end
        success = true
      end  
    rescue => error
      error(error.message, { :i18n => false })
    end
    
    success
  end
  
  #---
  
  def ssh_upload(local_path, remote_path, options = {}, &code)
    config  = Config.ensure(options)
    success = false
    
    begin
      if init_ssh_session
        Util::SSH.upload(node.public_ip, node.user, local_path, remote_path, config.export) do |name, sent, total|
          code.call(name, sent, total) if code
        end
        success = true
      end  
    rescue => error
      error(error.message, { :i18n => false })
    end
    
    success  
  end
  
  #---
  
  def ssh_exec(commands, options = {}, &code)
    config  = Config.ensure(options)
    results = nil
    
    if commands && commands = commands.clone
      if init_ssh_session
        results = Util::SSH.exec(node.public_ip, node.user, commands) do |type, command, data|
          code.call(type, command, data) if code  
        end
      end
    end
    results
  end
  
  #---
  
  def close_ssh_session
    Util::SSH.close_session(node.public_ip, node.user)
  end
  
  #---
  
  def ssh_terminal(user, options = {})
    Util::SSH.terminal(node.public_ip, user, Config.ensure(options).export)
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def ssh_wait_for_ready
    # Override in class if needed (see Fog Machine provider)
  end
end
end
end
end
