
module Coral
class RegexpEvent < Event

  #-----------------------------------------------------------------------------
  # Properties
  
  TYPE = :regexp

  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    options[:type] = TYPE
    
    super(options)
    
    if options.has_key?(:string)
      self.pattern = options[:string]
    end
  end
      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def pattern
    return property(:pattern, '', :string)
  end
  
  #---
   
  def pattern=pattern
    set_property(:pattern, string(pattern))  
  end
 
  #-----------------------------------------------------------------------------
  # Import / Export
  
  def export
    return "#{type}:#{pattern}"
  end
 
  #-----------------------------------------------------------------------------
  # Event handling
  
  def check(source)
    if source.match(/#{pattern}/)
      logger.debug("MATCH! -> #{pattern} matched #{source}") 
      return true                  
    end
    logger.debug("nothing -> #{pattern} - #{source}")
    return false
  end
end
end