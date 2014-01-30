
module Coral
module Plugin
class Provisioner < Base

  #-----------------------------------------------------------------------------
  # Provisioner plugin interface
  
  def normalize
    super
  end
  
  #---

  def initialized?(options = {})
  end
  
  #---
  
  def register
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
 
  def hiera_config
  end
  
  #-----------------------------------------------------------------------------
  # Provisioner operations
   
  def lookup(property, default = nil, options = {})
  end
  
  #--
  
  def import(files)
  end
  
  #---
  
  def include(resource_name, properties, options = {})
  end
  
  #---
  
  def provision(options = {})
  end
end
end
end
