
module Coral
module Plugin
class Builder < Base
  
  extend Mixin::ObjectInterface  
  
  #-----------------------------------------------------------------------------
  # Project plugin interface
   
  def normalize
    super
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  plugin_collection :config
  plugin_collection :provisioner

  #-----------------------------------------------------------------------------
  # Build operations

  def build(plugin_types = nil)
    foreach_plugin!(plugin_types) do |type, name, plugin|
      plugin.build(self)
    end  
  end
end
end
end
