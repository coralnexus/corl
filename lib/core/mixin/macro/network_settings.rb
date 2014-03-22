
module CORL
module Mixin
module Macro
module NetworkSettings
  
  def network_settings(_type)
    
    # Networks are inherited unless explicitely set
     
    define_method :network do
      plugin_parent
    end
 
    define_method :network= do |network|
      myself.plugin_parent = network
    end
  
    #---
  
    define_method :setting do |property, default = nil, format = false|
      network.send("#{_type}_setting", plugin_provider, plugin_name, property, default, format)
    end
  
    define_method :search do |property, default = nil, format = false|
      network.send("search_#{_type}", plugin_provider, plugin_name, property, default, format)
    end
  
    define_method :set_setting do |property, value = nil|
      network.send("set_#{_type}_setting", plugin_provider, plugin_name, property, value)
    end
  
    define_method :delete_setting do |property|
      network.send("delete_#{_type}_setting", plugin_provider, plugin_name, property)
    end
  
    #---
 
    define_method :[] do |name, default = nil, format = false|
      search(name, default, format)
    end
  
    #---
  
    define_method :[]= do |name, value|
      set_setting(name, value)
    end
    
    #---
  
    define_method :groups do
      array(myself[:settings])
    end     
  end
end
end
end
end
