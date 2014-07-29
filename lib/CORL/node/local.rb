
module CORL
module Node
class Local < Nucleon.plugin_class(:CORL, :node)
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize(reload)
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
