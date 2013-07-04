
module Coral
module Event
class Puppet < Plugin::Event
    
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def element(default = '')
    return get(:element, default, :string)
  end
  
  #---
 
  def element=element
    set(:element, string(element))
  end
  
  #---
  
  def operation(default = '')
    return get(:operation, default, :string)
  end
  
  #---
   
  def operation=operation
    set(:operation, string(operation))
  end
  
  #--
  
  def message(default = '')
    return get(:message, default, :string)
  end
  
  #---
   
  def message=message
    set(:message, string(message))
  end
  
  #-----------------------------------------------------------------------------
  # Plugin operations
  
  def normalize
    super
    
    if get(:string)
      items          = delete(:string).split(':')
      self.element   = items[0]
      self.operation = items[1]
      self.message   = items[2]
    end
    
    set(:name, "#{type}:#{element}:#{operation}:#{message}")
  end
  
  #-----------------------------------------------------------------------------
  # Event operations
  
  def check(source)
    if source.match(/notice:\s+(.+?):\s+(.+)\s*/i)
      source_element   = $1
      source_operation = ''
      source_message   = $2
                    
      source_elements  = source_element.split('/')
      source_operation = source_elements.pop.strip unless source_elements.last.match(/[\[\]]/)
                    
      if source_operation
        source_element = source_elements.join('/').strip
        
        if source_element.include?(element) && source_operation == operation && source_message.include?(message)
          return true
        end
      end
    end
    return false
  end
end
end
end
