
module CORL
module Node
class Rackspace < Fog
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
  
  def normalize(reload)
    super do
      region_info.import({
        :dfw => 'Dallas',
        :ord => 'Chicago',
        :lon => 'London (for UK accounts)'  
      })
      # Return machine provider
      :rackspace
    end
  end
      
  #-----------------------------------------------------------------------------
  # Checks
  
  def usable_image?(image)
    image.state != 'DELETED'
  end
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  #-----------------------------------------------------------------------------
  # Settings groups
    
  def machine_config
    super do |config|
      config.import({ 
        :provider         => 'rackspace', 
        :version          => :v2,
        :rackspace_region => region
      })
    
      config[:rackspace_username] = api_user if api_user
      config[:rackspace_api_key]  = api_key if api_key
      config[:rackspace_auth_url] = auth_url if auth_url
    end
  end
  
  #---
  
  def create_config
    { :name => hostname, :flavor_id => machine_type, :image_id => image }  
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
    sprintf("%-30s  %-35s  [ VCPUS: %-5s ] ( RAM: %6sMB | DISK: %4sGB )", 
      purple(machine_type_id(machine_type)),
      yellow(machine_type.name), 
      blue(machine_type.vcpus.to_s),       
      blue(machine_type.ram.to_s), 
      blue(machine_type.disk.to_s)
    )
  end
  
  #---
  
  def render_image(image)
    sprintf("[  %40s  ][ %10s ] %s", image_id(image), image.state, image.name)
  end
  
  #---
  
  def image_search_text(image)
    sprintf("%s %s %s", image_id(image), image.name, image.state)  
  end
end
end
end
