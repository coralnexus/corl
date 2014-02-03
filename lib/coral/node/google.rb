
coral_require(File.dirname(__FILE__), :fog)

#---

module Coral
module Node
class Google < Node::Fog
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
  
  def normalize
    super
    
    begin
      require 'google/api_client'
    rescue LoadError
      ui.warn("Please install the google-api-client gem before using the Google node provider.")
    end
  end
      
  #-----------------------------------------------------------------------------
  # Checks
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def project_name=project_name
    set(:project_name, project_name)
  end
  
  def project_name
    get(:project_name, nil)
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
 
  #---
  
  def machine_types
    machine.compute.machine_types if machine.compute
  end
    
  #-----------------------------------------------------------------------------
  # Settings groups
    
  def provider_info
    super do |config|          
      config.import({ 
        :provider => 'google'
      })
    
      config[:google_project] = project_name if project_name
      config[:google_client_email] = user_name if user_name
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
  
end
end
end
