
module Coral
module Node
class Rackspace < Plugin::Node
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize
    #super
    dbg('hello from rackspace node')
  end
       
  #-----------------------------------------------------------------------------
  # Checks
    
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
    
end
end
end
