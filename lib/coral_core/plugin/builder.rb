
module Coral
module Plugin
class Builder < Base
  
  extend Mixin::Macro::PluginInterface  
  
  #-----------------------------------------------------------------------------
  # Builder plugin interface
   
  def normalize
    super
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  plugin_collection :config, :plugin_type => :project
  
  plugin_collection :provisioner, :single_instance => true
  
  plugin_collection :library, :plural      => :libraries,
                              :plugin_type => :project

  #-----------------------------------------------------------------------------
  # Build operations

  def build(plugin_types = nil)
    each_plugin!(plugin_types) do |type, provider, plugin|
      plugin.build(self)
    end  
  end
end
end
end
