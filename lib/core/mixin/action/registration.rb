
module CORL
module Mixin
module Action
module Registration
        
  #-----------------------------------------------------------------------------
  # Registration definitions
    
  def register_node(name, default = nil, locale = nil, &code)
    name = name.to_sym
    
    register name, :str, default, locale do |value|
      validate_plugins(:CORL, :node, name, value) && ( ! code || code.call(value) )
    end
  end
  
  #---
    
  def register_nodes(name, default = nil, locale = nil, &code)
    name = name.to_sym
    
    register name, :array, default, locale do |values|
      validate_plugins(:CORL, :node, name, values) && ( ! code || code.call(values) )
    end
  end
end
end
end
end

