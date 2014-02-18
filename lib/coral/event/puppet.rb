
module Coral
module Event
class Puppet < Plugin::Event
  
  #-----------------------------------------------------------------------------
  # Puppet event interface
  
  def normalize
    super
    
    if get(:string)
      items          = string(delete(:string)).split(':')
      myself.element   = items[0]
      myself.operation = items[1]
      myself.message   = items[2]
    end
  end
    
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
  # Operations
  
  def render
    return "#{name}:#{element}:#{operation}:#{message}"
  end
  
  #---
  
  def check(source)
    if source.match(/notice:\s+(.+?):\s+(.+)\s*/i)
      source_element   = $1
      source_operation = ''
      source_message   = $2
                    
      source_elements  = source_element.split('/')
      source_operation = source_elements.pop.strip unless source_elements.last.match(/[\[\]]/)
                    
      if source_operation
        source_element = source_elements.join('/').strip
        success        = ( source_element.include?(element) && source_operation == operation && source_message.include?(message) )
        
        logger.debug("Checking puppet event with source #{source_element} #{source_operation} #{source_message}: #{success.inspect}")
        
        return success
      else
        logger.warn("Can not check puppet event because it is missing an operation")
      end
    end
    return false
  end
end
end
end
