
module Coral
module Plugin
class Network < Base
  
  ensure_plugin_collection 
  
  #-----------------------------------------------------------------------------
  # Cloud plugin interface
  
  def normalize
    @config = Config::Project.new(self._export)
    super
    
    init_nodes
  end
       
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  plugin_collection :node
end
end
end
