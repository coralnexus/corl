
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
        :region   => region.to_s
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
    sprintf("%-25s   %-50s  [ VCPUS: %-5s ] ( RAM: %6sMB | DISK: %8sGB )  ( BITS: %5s )", 
      purple(machine_type_id(machine_type)),
      yellow(machine_type.name), 
      blue(machine_type.cores.to_s),       
      blue(machine_type.ram.to_s), 
      blue(machine_type.disk.to_s), 
      blue(machine_type.bits.to_s)
    )
  end
  
  #---
  
  def render_image(image)
    location = image.location.split('/').first
    sprintf("%-23s [ %-10s | %-6s ]   %s ( %s )", purple(image_id(image)), blue(image.state), image.architecture, yellow(image.name), cyan(location))
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
