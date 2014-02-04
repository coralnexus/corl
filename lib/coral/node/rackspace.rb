
coral_require(File.dirname(__FILE__), :fog)

#---

module Coral
module Node
class Rackspace < Node::Fog
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
      
  #-----------------------------------------------------------------------------
  # Checks
  
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
    
  def provider_info
    super do |config|
      config.import({ 
        :provider         => 'rackspace', 
        :version          => :v2,
        :rackspace_region => region
      })
    
      config[:rackspace_username] = user_name if user_name
      config[:rackspace_api_key]  = api_key if api_key
      config[:rackspace_auth_url] = auth_url if auth_url
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
  
end
end
end
