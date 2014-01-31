
module Coral
module Plugin
class Network < Base
  
  init_plugin_collection 
  
  #-----------------------------------------------------------------------------
  # Cloud plugin interface
  
  def normalize
    super
    
    logger.info("Initializing sub configuration from source with: #{self._export}")
    
    self.config = Coral.configuration(self._export)
    
    init_nodes
  end
  
  #-----------------------------------------------------------------------------
  # Checks
  
  def has_nodes?(provider = nil)
    return nodes(provider).empty? ? false : true
  end
       
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  plugin_collection :node
  
  #-----------------------------------------------------------------------------
  # Operations
  
end
end
end
