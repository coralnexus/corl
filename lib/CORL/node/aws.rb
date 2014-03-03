
module CORL
module Node
class Aws < Fog
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
  
  def normalize(reload)
    super do
      :aws
    end
  end
       
  #-----------------------------------------------------------------------------
  # Checks
  
  def usable_image?(image)
    image.state == 'available' && image.name
  end
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def regions
    [
      'us-east-1', 
      'us-west-1', 
      'us-west-2',
      'eu-west-1',
      'ap-northeast-1', 
      'ap-southeast-1', 
      'ap-southeast-2',       
      'sa-east-1'
    ]
  end
  
  #-----------------------------------------------------------------------------
  # Settings groups
    
  def machine_config
    super do |config|
      config.import({ 
        :provider => 'AWS',
        :region   => region
      })
    
      config[:aws_access_key_id]     = api_user if api_user
      config[:aws_secret_access_key] = api_key if api_key
    end
  end
  
  #---
  
  def create_config
    { :flavor_id => machine_type, :image_id => image }  
  end
  
  #-----------------------------------------------------------------------------
  # Node operations
  
  def create(options = {})
    super do |op, config|
      if op == :config
        config.defaults(create_config)
        config.defaults({ :username => user })
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
    location = image.location.split('/').first
    sprintf("[  %20s  ][ %10s ] %10s - %s (%s)", image_id(image), image.state, image.architecture, image.name, location)
  end
  
  #---
  
  def image_search_text(image)
    location = image.location.split('/').first
    location = location.match(/^\d+$/) ? '' : location
    sprintf("%s %s %s %s %s %s %s", image_id(image), image.name, image.description, image.state, image.architecture, image.owner_id, location)
  end
end
end
end
