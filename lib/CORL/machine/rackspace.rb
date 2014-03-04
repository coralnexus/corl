
module CORL
module Machine
class Rackspace < Fog
 
  #-----------------------------------------------------------------------------
  # Checks
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
 
  #-----------------------------------------------------------------------------
  # Management

  def init_server
    super do
      myself.plugin_name = @server.id
      
      node[:id]           = plugin_name
      node[:public_ip]    = @server.public_ip_address
      node[:private_ip]   = @server.private_ip_address    
      node[:machine_type] = @server.flavor.id
      node[:image]        = @server.image.id    
      node.user           = @server.username unless node.user
      
      @server.private_key_path = node.private_key if node.private_key
      @server.public_key_path  = node.public_key if node.public_key
    end  
  end
  
  #---
  
  def reload(options = {})
    super do
      config = Config.ensure(options)
      logger.debug("Rebooting Rackspace machine #{plugin_name}")
      
      success = server.reboot(config.get(:type, 'SOFT'))
      
      server.wait_for { ready? } if success
      success
    end
  end
end
end
end