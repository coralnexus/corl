
module Coral
module Event
class Regex < Plugin::Event
 
  #-----------------------------------------------------------------------------
  # Regular expression event interface
  
  def normalize
    super
    
    if get(:string)
      self.pattern = delete(:string)
    end
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def pattern(default = '')
    return get(:pattern, default)
  end
  
  #---
   
  def pattern=pattern
    set(:pattern, string(pattern))  
  end
  
  #-----------------------------------------------------------------------------
  # Operations
  
  def render
    return "#{name}:#{pattern}"
  end
  
  #---
   
  def check(source)
    if pattern.empty?
      return true if source.match(/#{pattern}/)                 
      return false
    end
    return true
  end
end
end
end
