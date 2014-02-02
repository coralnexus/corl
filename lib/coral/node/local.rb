
module Coral
module Node
class Local < Plugin::Node
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize
    super
    create_machine(:physical, extended_config(:machine))
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
