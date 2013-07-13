
module Coral
class Core < Config
  
  #-----------------------------------------------------------------------------
  # Properties
  
  @@ui = Util::Interface.new("coral")
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    config = Config.ensure(options)
    
    @ui = Util::Interface.new(config)
  end
  
  #---
  
  def inspect
    "#<#{self.class}: >"
  end
  
  #-----------------------------------------------------------------------------
  # Accessor / Modifiers
  
  attr_accessor :ui
  
  #-----------------------------------------------------------------------------
  
  def self.ui
    return @@ui
  end
  
  #---
  
  def self.logger
    return @@ui.logger
  end
  
  #--- 
   
  def logger
    return self.class.logger
  end
  
  #---
 
  def logger=logger
    self.class.logger = logger
  end
 
  #-----------------------------------------------------------------------------
  # General utilities
 
end
end