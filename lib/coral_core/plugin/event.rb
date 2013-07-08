
module Coral
module Plugin
class Event < Base

  #-----------------------------------------------------------------------------
  # Event plugin interface

  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers

 
  #-----------------------------------------------------------------------------
  # Plugin operations


  #-----------------------------------------------------------------------------
  # Event operations
  
  def render
    return name
  end
  
  #---
 
  def check(source)
    # Implement in sub classes
    return true
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info(data)  
    data = data.split(/\s*,\s*/) if data.is_a?(String)
    return super(data)
  end
  
  #---
   
  def self.translate(data)
    info = super(data)
    
    case data        
    when String
      components = data.split(':')
      
      info[:provider] = components.shift
      info[:string]   = components.join(':')
    end
    return Plugin.translate(plugin_type, info[:provider], info)  
  end
end
end
end
