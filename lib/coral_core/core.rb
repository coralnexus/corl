
module Coral
class Core < Config
  
  #-----------------------------------------------------------------------------
  # Properties
  
  @@ui = Util::Interface.new("coral")
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(data = {}, defaults = {}, force = true)
    super(data, defaults, force)
    
    logger.debug("Setting instance interface")
    @ui = Util::Interface.new(export)
  end
  
  #---
  
  def inspect
    "#<#{self.class}>"
  end
  
  #-----------------------------------------------------------------------------
  # Accessor / Modifiers
  
  attr_accessor :ui
  
  #---
  
  def self.ui
    return @@ui
  end
  
  #---
  
  def self.logger
    return @@ui.logger
  end
  
  #---
 
  def self.logger=logger
    self.class.logger = logger
  end
  
  #--- 
   
  def logger
    return self.class.logger
  end
 
  #-----------------------------------------------------------------------------
  # General utilities
 
end
end