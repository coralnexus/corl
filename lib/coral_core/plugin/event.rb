
module Coral
module Plugin
class Event < Base

  #-----------------------------------------------------------------------------
  # Event plugin interface
  
  def initialized?(options = {})
    return super(options)    
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def type(default = nil)
    return get(:type, default)
  end
  
  #-----------------------------------------------------------------------------
  # Plugin operations
    
  def normalize
    super
    set(:name, "#{type}:base")
    # Override in sub classes
  end

  #-----------------------------------------------------------------------------
  # Event operations
 
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
        
        if block_given?
          event = yield(element)
        else
          case element        
          when String
            event = split_event_string(element)
                
          when Hash          
            event = element
          end
        end
        
        unless event.empty?
          events << event
        end
      end
    end
    return events
  end
  
  #---
  
  def self.split_event_string(data)
    info          = {}
       
    components    = data.split(':')
    info[:type]   = components.shift
    info[:string] = components.join(':')
    
    return info
  end
end
end
end
