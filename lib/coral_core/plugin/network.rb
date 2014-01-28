
module Coral
module Plugin
class Network < Base
  
  init_plugin_collection 
  
  #-----------------------------------------------------------------------------
  # Cloud plugin interface
  
  def normalize
    super
    
    logger.info("Initializing sub configuration from source with: #{self._export}")
    
    config = Coral.configuration(self._export)
    
    init_nodes
  end
       
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  plugin_collection :node
end
end
end
