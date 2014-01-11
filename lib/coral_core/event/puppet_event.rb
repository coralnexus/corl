module Coral
class PuppetEvent < Event

  #-----------------------------------------------------------------------------
  # Properties
  
  TYPE = :puppet
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    options[:type] = TYPE
    
    super(options)
    
    if options.has_key?(:string)
      items = options[:string].split(':')
      self.element = items[0]
      self.operation = items[1]
      self.message = items[2]
    end
  end
    
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def element
    return property(:element, '', :string)
  end
  
  #---
 
  def element=element
    set_property(:element, string(element))
  end
  
  #---
  
  def operation
    return property(:operation, '', :string)
  end
  
  #---
   
  def operation=operation
    set_property(:operation, string(operation))
  end
  
  #--
  
  def message
    return property(:message, '', :string)
  end
  
  #---
   
  def message=message
    set_property(:message, string(message))
  end
  
  #-----------------------------------------------------------------------------
  # Import / Export
  
  def export
    return "#{type}:#{element}:#{operation}:#{message}"
  end
  
  #-----------------------------------------------------------------------------
  # Event handling
  
  def check(source)
    if source.match(/notice:\s+(.+?):\s+(.+)\s*/i)
      source_element = $1
      source_operation = ''
      source_message = $2
                    
      source_elements = source_element.split('/')
      source_operation = source_elements.pop.strip unless source_elements.last.match(/[\[\]]/)
                    
      if source_operation
        source_element = source_elements.join('/').strip
        
        logger.debug("#{source_element} includes: #{element} -- " + ( source_element.include?(element) ? 'true' : 'false' ))
        logger.debug("#{source_operation} is: #{operation} -- " + ( source_operation == operation ? 'true' : 'false' ))
        logger.debug("#{source_message} includes: #{message} -- " + ( source_message.include?(message) ? 'true' : 'false' ))
        
        if source_element.include?(element) && source_operation == operation && source_message.include?(message)
            logger.debug("MATCH! -> #{element} - #{operation} - #{message}")
            return true
        end
      end
    end
    logger.debug("nothing -> #{element} - #{operation} - #{message}")
    return false
  end
end
end