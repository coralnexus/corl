
module Coral
module Plugin
class Context < Base

  #-----------------------------------------------------------------------------
  # Context plugin interface

 
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers

  
  #-----------------------------------------------------------------------------
  # Plugin operations


  #-----------------------------------------------------------------------------
  # Context operations
  
  def filter(plugins)
    return plugins
  end
  
  #---
  
  def translate(value)
    return Util::Data.value(value)
  end
end
end
end
