
module CORL
module Mixin
module Action
module Registration
        
  #-----------------------------------------------------------------------------
  # Options
    
  def register_node(name, default = nil)
    name = "#{name}_node"
    
    register name, :str, default do |value|
      validate_plugins(:CORL, :node, name, value)
    end
  end
  
  #---
    
  def register_nodes(name, default = nil)
    name = "#{name}_nodes"
    
    register name, :array, default do |values|
      validate_plugins(:CORL, :node, name, values)
    end
  end
end
end
end
end

