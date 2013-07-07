
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
  
  def self.build_info(data = {})  
    events = []
    
    if data.is_a?(String)
      data = data.split(/\s*,\s*/)
    elsif data.is_a?(Hash)
      data = [ data ]
    end
    
    if data.is_a?(Array)
      data.each do |element|
        event = {}
        
        case element        
        when String
          event = split_event_string(element)                
        when Hash          
          event = element
        end
                
        unless event.empty?
          events << normalize(:event, event, :regex)
        end
      end
    end
    return events
  end
  
  #---
  
  def self.split_event_string(data)
    info = {}
       
    components      = data.split(':')
    info[:provider] = components.shift
    info[:string]   = components.join(':')
    
    return info
  end
end
end
end
