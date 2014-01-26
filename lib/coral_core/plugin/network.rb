
module Coral
module Plugin
class Network < Base
  
  init_plugin_collection 
  
  #-----------------------------------------------------------------------------
  # Cloud plugin interface
  
  def normalize
    logger.info("Initializing sub configuration from source with: #{self._export}")
    @config = Config::Source.new(self._export)
    
    super
    
    init_nodes
  end
       
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  plugin_collection :node
end
end
end
