
module CORL
module Action
class Image < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure,
            :image_create_failure  
    end
  end
  
  #---
  
  def arguments
    [ :nodes ]
  end
 
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      info('corl.actions.image.start')
      
      if network && node
        unless node.create_image
          myself.status = code.image_create_failure
        end  
      else
        myself.status = code.network_failure
      end    
    end
  end
end
end
end
