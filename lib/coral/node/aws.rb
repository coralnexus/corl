
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
        config[:private_key_path] = private_key if private_key
        config[:public_key_path]  = public_key if public_key
        
        found_images = images.find do |image| 
          image.name =~ /Ubuntu/
        end
        image_name = nil
        image_name = found_images.first.id if found_images.length
        
        config.defaults({
          :name         => hostname,
          :machine_type => machine_types.first.id,
          :image_name   => image_name
        })
      end
    end
  end
 
  #-----------------------------------------------------------------------------
  # Utilities
  
end
end
end
