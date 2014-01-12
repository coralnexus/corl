
module Coral
module Machine
class Fog < Plugin::Machine
  
  include Mixin::SubConfig
  
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
    set(:compute, Fog::Compute.new(_export))
  end
  protected :set_connection
  
  #---
  
  def compute(default = nil)
    return get(:compute, default)
  end
  
  #---
  
  def server
    return get(:server)
  end
  
  #---
  
  def id=id
    set(:server, compute.servers.get(id)) if id  
  end
  
  #---
  
  def id
    return ( server ? server.id : nil )
  end
  
  #---
  
  def name
    return server.name if server
    return nil
  end
  
  #---
  
  def hostname
    return name
  end
  
  #---
  
  def created
    return server.created if server
    return nil
  end
  
  #---
  
  def updated
    return server.updated if server
    return nil
  end
  
  #---
  
  def state
    return server.state if server
    return nil
  end
  
  #---
  
  def addresses
    return server.addresses if server
    return nil
  end
  
  #---
  
  def public_ip
    return server.public_ip_address if server
    return nil
  end
  
  #---
  
  def private_ip
    return server.private_ip_address if server
    return nil
  end
  
  #---
  
  def flavors
    return compute.flavors if compute
    return nil
  end
  
  #---
  
  def flavor
    return server.flavor if server
    return nil
  end
  
  #---
  
  def images
    return compute.images if compute
    return nil
  end
  
  #---
  
  def image
    return server.image if server
    return nil
  end
  
  #-----------------------------------------------------------------------------
  # Management

  def create(options = {})
    success = super(options)
    if success && ! created?
      set(:server, compute.servers.bootstrap(options))
    end
    return success
  end
  
  #---
  
  def update(options = {})
    success = super(options)
    if success && created?
      return server.update(options)
    end
    return success
  end
  
  #---
  
  def start(options = {})
    success = super(options)
    if success
      unless created?
        return create(options)
      end
      unless running?
        server_info = compute.servers.create(options)
      
        Fog.wait_for do
          compute.servers.get(server_info.id).ready? ? true : false
        end      
        @server = compute.servers.get(server_info.id)
      end
    end
    return success
  end
  
  #---
  
  def stop(options = {})
    success = super(options)
    if success && running?
      if image_id = create_image(name)
      
        Fog.wait_for do
          compute.images.get(image_id).ready? ? true : false
        end
      
        server.destroy
        return image_id
      end
    end
    return success
  end
  
  #---
  
  def reload(options = {})
    success = super(options)
    if success && created?
      # Don't quite know what this should do yet??
      return server.reboot(options)  
    end
    return success
  end

  #---

  def destroy(options = {})
    success = super(options)   
    if success && created?
      return server.destroy(options)  
    end
    return success
  end
  
  #-----------------------------------------------------------------------------
  
  def create_image(name, options = {})
    success = super(options)
    if success && created?
      image = server.create_image(name, options)
      return ( image ? image.id : false )
    end
    return success
  end
  
  #-----------------------------------------------------------------------------
  
  def exec(options = {})
    success = super(options)
    if success && running?
      if commands = options.delete(:commands)
        return server.ssh(commands, options)
      end
    end
    return success
  end
  
  #-----------------------------------------------------------------------------
  # Utilities

end
end
end