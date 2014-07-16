
module CORL
module Node
class AWS < Fog
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
  
  def normalize(reload)
    super do
      region_info.import({
        'us-east-1'      => 'US East       -- North Virginia', 
        'us-west-1'      => 'US West       -- North California', 
        'us-west-2'      => 'US West       -- Oregon',
        'eu-west-1'      => 'EU            -- Ireland',
        'ap-northeast-1' => 'Asia Pacific  -- Tokyo', 
        'ap-southeast-1' => 'Asia Pacific  -- Singapore', 
        'ap-southeast-2' => 'Asia Pacific  -- Sydney',       
        'sa-east-1'      => 'South America -- São Paulo'
      })
      
      # Return machine provider      
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
    { :flavor_id => machine_type, :image_id => image, :username => user }  
  end
  
  #-----------------------------------------------------------------------------
  # Node operations
  
  def create(options = {})
    super do |op, config|
      if op == :config
        config.defaults(create_config)
      end
    end
  end
 
  #---
  
  def start(options = {})
    super do |op, config|
      if op == :config
        config.defaults(create_config)
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
