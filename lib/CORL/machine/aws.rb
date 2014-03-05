
module CORL
module Machine
class Aws < Fog
 
  #-----------------------------------------------------------------------------
  # Checks
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def set_connection
    require 'unf'
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
 
  def init_ssh(ssh_port)
    # Security group initialization
    if compute && ssh_port != 22
      ensure_security_group("CORL_SSH_#{ssh_port}", ssh_port)
    end
  end
  
  #--- 

  def create(options = {})
    super do |config|
      # Keypair initialization
      if key_pair = compute.key_pairs.get(keypair_name)
        key_pair.destroy
      end
      compute.key_pairs.create(
        :name       => keypair_name,
        :public_key => Util::Disk.read(node.public_key)
      )      
      config[:key_name] = keypair_name
    end
  end
  
  #---
  
  def reload(options = {})
    super do |config|
      success = server.reboot
      
      server.wait_for { ready? } if success
      success
    end
  end
  
  #---
 
  def create_image(options = {})
    super do |image_name, config, success|
      image_name        = image_name.gsub(/[^A-Za-z0-9\(\)\.\-\_\/]+/, '_')
      image_description = config.get(:description, "CORL backup image")
      
      data     = compute.create_image(server.identity, image_name, image_description)
      image_id = data.body['imageId']
      
      ::Fog.wait_for do
        compute.describe_images('ImageId' => image_id).body['imagesSet'].first['imageState'] == 'available'
      end
      
      if image_id
        node[:image] = image_id
        success      = true
      end
      success
    end
  end
  
  #---

  def destroy(options = {})
    super do |config|
      unless config.get(:stop, false)
        # Keypair destruction
        key_pair.destroy if key_pair = compute.key_pairs.get(keypair_name)
      end
      true  
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def keypair_name
    "CORL_#{node.plugin_name}"  
  end
  
  #---
  
  def ensure_security_group(group_name, from_port, to_port = nil, options = {})
    config         = Config.ensure(options)
    security_group = compute.security_groups.get(group_name)
    cidrip         = config.get(:cidrip, '0.0.0.0/0')
    protocol       = config.get(:protocol, 'tcp')
    to_port        = from_port if to_port.nil?
    
    if security_group.nil?
      security_group = compute.security_groups.create(
        :name        => group_name,
        :description => config.get(:description, "Opening port range: #{from_port} to #{to_port}")  
      )          
      raise unless security_group # TODO: Better error class       
    end
        
    authorized = false
    if security_group.ip_permissions  
      authorized = security_group.ip_permissions.detect do |ip_permission|
        ip_permission['ipRanges'].first && ip_permission['ipRanges'].first['cidrIp'] == cidrip &&
        ip_permission['fromPort'] == from_port &&
        ip_permission['ipProtocol'] == protocol &&
        ip_permission['toPort'] == to_port
      end
    end
    unless authorized
      security_group.authorize_port_range(Range.new(from_port, to_port))
    end
      
    if server
      server.groups = [ group_name ] | server.groups
      server.save
    end
  end
end
end
end