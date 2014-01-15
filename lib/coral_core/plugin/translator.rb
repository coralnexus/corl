
module Coral
module Plugin
class Translator < Base

  #-----------------------------------------------------------------------------
  # Translator plugin interface
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers


  #-----------------------------------------------------------------------------
  # Operations
  
  def parse(raw)
    # Implement in sub classes.
    return raw
  end
  
  #---
  
  def generate(properties)
    # Implement in sub classes.
    return properties
  end
end
end
end
