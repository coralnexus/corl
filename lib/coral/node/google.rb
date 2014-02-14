
coral_require(File.dirname(__FILE__), :fog)

#---

module Coral
module Node
class Google < Node::Fog
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
  
  #-----------------------------------------------------------------------------
  # Checks
  
  def usable_image?(image)
    image.status == 'READY' && ! image.description.match(/DEPRECATED/i)
  end
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def project_name=project_name
    self[:project_name] = project_name
  end
  
  def project_name
    self[:project_name]
  end
  
  #---
  
  def regions
    [
      'us-central1-a',
      'us-central1-b',
      'europe-west1-a',
      'europe-west1-b'     
    ]
  end
  
  #-----------------------------------------------------------------------------
  # Settings groups
    
  def provider_info
    super do |config|          
      config.import({ 
        :provider => 'google'
      })
      
      config[:google_project]      = project_name if project_name
      config[:google_client_email] = api_user if api_user
      config[:google_key_location] = api_key if api_key
    end
  end
  
  #-----------------------------------------------------------------------------
  # Node operations
  
  def create(options = {})
    super do |op, config|
      if op == :config
        config[:private_key_path] = private_key if private_key
        config[:public_key_path]  = public_key if public_key
        
        config.defaults({
          :name         => hostname,
          :machine_type => machine_type,
          :image_name   => image
        })
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def machine_type_id(machine_type)
    machine_type.name
  end
  
  #---
  
  def render_machine_type(machine_type)
    sprintf("[  %20s  ][ VCPUS: %2i ] %-55s ( RAM: %6iMB | DISK: %3iGB )  ( MAX DISKS: %2i | MAX STORAGE: %6iGB )", 
      machine_type_id(machine_type), 
      machine_type.guest_cpus, 
      machine_type.description, 
      machine_type.memory_mb, 
      machine_type.image_space_gb, 
      machine_type.maximum_persistent_disks, 
      machine_type.maximum_persistent_disks_size
    )
  end
  
  #---
  
  def image_id(image)
    image.name
  end
  
  #---
  
  def render_image(image)
    sprintf("[  %40s  ][ %10s ] %s - %s", image_id(image), image.status, image.description, image.project)
  end
  
  #---
  
  def image_search_text(image)
    sprintf("%s %s %s %s", image.name, image.description, image.status, image.project)  
  end
end
end
end
