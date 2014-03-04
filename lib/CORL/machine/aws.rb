
module CORL
module Machine
class Aws < Fog
 
  #-----------------------------------------------------------------------------
  # Checks
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def set_connection
    super
    Kernel.load File.join(File.dirname(__FILE__), '..', '..', 'core', 'mod', 'fog_aws_server.rb')
  end
 
  #-----------------------------------------------------------------------------
  # Management

  def init_server
    super do
      myself.plugin_name = @server.id
      
      node[:id]           = plugin_name
      node[:public_ip]    = @server.public_ip_address
      node[:private_ip]   = @server.private_ip_address    
      node[:machine_type] = @server.flavor_id
      node[:image]        = @server.image_id    
      node.user           = @server.username unless node.user
      
      @server.private_key_path = node.private_key if node.private_key
      @server.public_key_path  = node.public_key if node.public_key
    end  
  end
  
  #---
 
  def create(options = {})
    super do |method_config|
      # Keypair initialization
      keypair_name = "CORL_#{node.plugin_name}"
      
      if key_pair = compute.key_pairs.get(keypair_name)
        key_pair.destroy
      end
      compute.key_pairs.create(
        :name       => keypair_name,
        :public_key => Util::Disk.read(node.public_key)
      )      
      method_config[:key_name] = keypair_name
      
      # Security group initialization
      ssh_port = 55 #node.ssh_port
      
      if ssh_port != 22
        group_name = "CORL_SSH_#{ssh_port}"
        
        security_group = compute.security_groups.get(group_name)
        if security_group.nil?
          security_group = compute.security_groups.create(
            :name        => group_name,
            :description => "CORL SSH access to port #{ssh_port}"  
          )          
          raise unless security_group          
        end
        
        authorized = false
        if security_group.ip_permissions  
          authorized = security_group.ip_permissions.detect do |ip_permission|
            ip_permission['ipRanges'].first && ip_permission['ipRanges'].first['cidrIp'] == '0.0.0.0/0' &&
            ip_permission['fromPort'] == ssh_port &&
            ip_permission['ipProtocol'] == 'tcp' &&
            ip_permission['toPort'] == ssh_port
          end
        end
        unless authorized
          security_group.authorize_port_range(Range.new(ssh_port, ssh_port))
        end                
        method_config[:groups] = [ "default", group_name ]
      end
    end
  end
  
  #---
  
  def reload(options = {})
    super do
      logger.debug("Rebooting AWS machine #{plugin_name}")      
      success = server.reboot
      
      server.wait_for { ready? } if success
      success
    end
  end
end
end
end