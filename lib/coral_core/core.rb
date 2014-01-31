
module Coral
class Core < Config
  
  #-----------------------------------------------------------------------------
  # Properties
  
  @@ui = Util::Interface.new("core")
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(data = {}, defaults = {}, force = true)
    super(data, defaults, force)
    
    class_label      = self.class.to_s.downcase.gsub(/^coral::/, '')
    interface_config = Config.new(export).defaults({ :logger => class_label, :resource => class_label })
    
    @ui = Util::Interface.new(interface_config)
    logger.debug("Initialized instance interface")
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
    @ui.logger = logger
  end
  
  #--- 
   
  def logger
    return @ui.logger
  end
 
  #-----------------------------------------------------------------------------
  # General utilities
 
end
end