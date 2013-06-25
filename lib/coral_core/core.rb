
module Coral
class Core
  
  #-----------------------------------------------------------------------------
  # Properties
  
  @@ui = Interface.new("coral")
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    config = Config.ensure(options)
    
    @ui = Interface.new(config)
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

  def self.symbol_map(data)
    return Util::Data.symbol_map(data)
  end
  
  #---
  
  def symbol_map(data)
    return self.class.symbol_map(data)
  end
  
  #---
  
  def self.string_map(data)
    return Util::Data.string_map(data)
  end
  
  #---
  
  def string_map(data)
    return self.class.string_map(data)
  end
  
  #-----------------------------------------------------------------------------
      
  def self.filter(data, method = false)
    return Util::Data.filter(data, method)
  end
  
  #---
  
  def filter(data, method = false)
    return self.class.filter(data, method)
  end
    
  #-----------------------------------------------------------------------------
          
  def self.array(data, default = [], split_string = false)
    return Util::Data.array(data, default, split_string)
  end
  
  #---
  
  def array(data, default = [], split_string = false)
    return self.class.array(data, default, split_string)
  end
    
  #---
        
  def self.hash(data, default = {})
    return Util::Data.hash(data, default)
  end
  
  #---
  
  def hash(data, default = {})
    return self.class.hash(data, default)
  end
    
  #---
         
  def self.string(data, default = '')
    return Util::Data.string(data, default)
  end
  
  #---
  
  def string(data, default = '')
    return self.class.string(data, default)
  end
    
  #---
         
  def self.symbol(data, default = :undefined)
    return Util::Data.symbol(data, default)
  end
  
  #---
  
  def symbol(data, default = '')
    return self.class.symbol(data, default)
  end
     
  #---
    
  def self.test(data)
    return Util::Data.test(data)
  end
  
  #---
  
  def test(data)
    return self.class.test(data)
  end  
end
end