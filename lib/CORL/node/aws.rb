
module CORL
module Node
class Aws < Node::Fog
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
      
  #-----------------------------------------------------------------------------
  # Checks
  
  def usable_image?(image)
    image.state == 'available' && image.name
  end
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def regions
    [
      'us-west-2a',
      'us-west-2b',
      'us-west-2c'
    ]
  end
  
  #-----------------------------------------------------------------------------
  # Settings groups
    
  def machine_config
    super do |config|
      config.import({ 
        :provider => 'AWS'
      })
    
      config[:aws_access_key_id]     = api_user if api_user
      config[:aws_secret_access_key] = api_key if api_key
    end
  end
  
  #-----------------------------------------------------------------------------
  # Node operations
  
  def create(options = {})
    super do |op, config|
      if op == :config
        config[:private_key] = private_key if private_key
        config[:public_key]  = public_key if public_key
        
        config.defaults({
          :name      => hostname,
          :flavor_id => machine_type,
          :image_id  => image
        })
      end
    end
  end
 
  #-----------------------------------------------------------------------------
  # Utilities
  
  def render_machine_type(machine_type)
    sprintf("[  %20s  ][ VCPUS: %5.1f ] %-40s ( RAM: %6iMB | DISK: %8iGB )  ( BITS: %2i )", 
      machine_type_id(machine_type), 
      machine_type.cores, 
      machine_type.name, 
      machine_type.ram, 
      machine_type.disk, 
      machine_type.bits
    )
  end
  
  #---
  
  def render_image(image)
    sprintf("[  %20s  ][ %10s ] %10s - %s", image_id(image), image.state, image.architecture, image.name)
  end
  
  #---
  
  def image_search_text(image)
    sprintf("%s %s %s %s %s", image_id(image), image.name, image.description, image.state, image.architecture)
  end
end
end
end
