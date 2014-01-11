
module Coral
module Plugin
class Network < Base
  
  dbg('hello from Coral::Plugin::Network')
  
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
