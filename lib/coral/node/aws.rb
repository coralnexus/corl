
coral_require(File.dirname(__FILE__), :fog)

#---

module Coral
module Node
class Aws < Node::Fog
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
      
  #-----------------------------------------------------------------------------
  # Checks
  
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
    
  def provider_info
    super do |config|
      config.import({ 
        :provider => 'AWS'
      })
    
      config[:aws_access_key_id] = user_name if user_name
      config[:aws_secret_access_key]  = api_key if api_key
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
