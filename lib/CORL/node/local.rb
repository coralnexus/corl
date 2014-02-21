
module CORL
module Node
class Local < CORL.plugin_class(:node)
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize
    super
    myself.machine = create_machine(:machine, :physical, machine_config)
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
