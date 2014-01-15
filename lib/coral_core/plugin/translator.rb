
module Coral
module Plugin
class Translator < Base

  #-----------------------------------------------------------------------------
  # Translator plugin interface

 
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers


  #-----------------------------------------------------------------------------
  # Operations
  
  def parse(raw, options = {})
    # Implement in sub classes.
    return raw
  end
  
  #---
  
  def generate(properties, options = {})
    # Implement in sub classes.
    return properties
  end
end
end
end
