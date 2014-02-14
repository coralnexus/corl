
module Coral
module Node
class Local < Plugin::Node
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize
    super
    self.machine = create_machine(:machine, :physical, machine_config)
  end
       
  #-----------------------------------------------------------------------------
  # Checks
  
  def local?
    true
  end  
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
 
end
end
end
