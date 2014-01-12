
module Coral
module Plugin
class Network < Base
  
  extend Mixin::Macro::PluginInterface  
  
  #-----------------------------------------------------------------------------
  # Cloud plugin interface
  
  def normalize
    super
  end
       
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  #plugin_collection :node
end
end
end
