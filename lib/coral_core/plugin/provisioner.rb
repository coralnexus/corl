
module Coral
module Plugin
class Provisioner < Base

  #-----------------------------------------------------------------------------
  # Provisioner plugin interface

  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
 
  def hiera_config
  end
  
  #-----------------------------------------------------------------------------
  # Plugin operations


  #-----------------------------------------------------------------------------
  # Provisioner operations
   
  def lookup(property, default = nil, options = {})
    # Implement in sub classes    
  end
  
  #--
  
  def import(files)
    # Implement in sub classes  
  end
  
  #---
  
  def include(resource_name, properties, options = {})
    # Implement in sub classes  
  end
  
  #---
  
  def provision(options = {})
    # Implement in sub classes   
  end
end
end
end
