
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
  
    define_method :search do |property, default = nil, format = false, extra_groups = []|
      network.send("search_#{_type}", plugin_provider, plugin_name, property, default, format, extra_groups)
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
  
    define_method :cache do
      network.cache
    end
  
    define_method :cache_setting do |keys, default = nil, format = false|
      cache.get([ _type, plugin_provider, plugin_name, keys ].flatten, default, format)
    end

    define_method :set_cache_setting do |keys, value|
      cache.set([ _type, plugin_provider, plugin_name, keys ].flatten, value)
    end

    define_method :delete_cache_setting do |keys|
      cache.delete([ _type, plugin_provider, plugin_name, keys ].flatten)
    end

    define_method :clear_cache do
      cache.delete([ _type, plugin_provider, plugin_name ])
    end

    #---
  
    define_method :groups do
      array(myself[:settings])
    end
    
    #---
    
    define_method :add_groups do |groups|
      myself[:settings] = array(setting(:settings)) | array(groups)
    end
    
    #---
    
    define_method :remove_groups do |groups|
      myself[:settings] = array(setting(:settings)) - array(groups)
    end    
  end
end
end
end
end
