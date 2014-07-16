
module CORL
module Mixin
module Action
module Registration
        
  #-----------------------------------------------------------------------------
  # Registration definitions
    
  def register_network_provider(name, default = nil, locale = nil, &code)
    register_plugin_provider(:CORL, :network, name.to_sym, default, locale, &code)
  end
  
  #---
    
  def register_network_providers(name, default = nil, locale = nil, &code)
    register_plugin_providers(:CORL, :network, name.to_sym, default, locale, &code)
  end
  
  #---
    
  def register_network(name, default = nil, locale = nil, &code)
    register_plugin(:CORL, :network, name.to_sym, default, locale, &code)
  end
  
  #---
    
  def register_networks(name, default = nil, locale = nil, &code)
    register_plugins(:CORL, :network, name.to_sym, default, locale, &code) 
  end
  
  #---
   
  def register_node_provider(name, default = nil, locale = nil, &code)
    register_plugin_provider(:CORL, :node, name.to_sym, default, locale, &code)
  end
  
  #---
    
  def register_node_providers(name, default = nil, locale = nil, &code)
    register_plugin_providers(:CORL, :node, name.to_sym, default, locale, &code)
  end
  
  #---
    
  def register_node(name, default = nil, locale = nil, &code)
    register_plugin(:CORL, :node, name.to_sym, default, locale, &code)
  end
  
  #---
    
  def register_nodes(name, default = nil, locale = nil, &code)
    register_plugins(:CORL, :node, name.to_sym, default, locale, &code) 
  end
end
end
end
end

