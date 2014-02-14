
coral_require(File.dirname(__FILE__), :fog)

#---

module Coral
module Node
class Rackspace < Node::Fog
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
      
  #-----------------------------------------------------------------------------
  # Checks
  
  def usable_image?(image)
    image.state != 'DELETED'
  end
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def regions
    [ 
      :dfw, # Dallas
      :ord, # Chicago
      :lon  # London (for UK accounts)
    ]
  end
 
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
  
  #-----------------------------------------------------------------------------
  # Node operations
  
  def create(options = {})
    super do |op, config|
      if op == :config
        config.defaults({
          :name      => name,
          :flavor_id => machine_type,
          :image_id  => image
        })
      end
    end
  end
 
  #-----------------------------------------------------------------------------
  # Utilities
  
  def render_machine_type(machine_type)
    sprintf("[  %20s  ][ VCPUS: %2i ] %-30s ( RAM: %6iMB | DISK: %4iGB )", 
      machine_type_id(machine_type), 
      machine_type.vcpus, 
      machine_type.name, 
      machine_type.ram, 
      machine_type.disk
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
