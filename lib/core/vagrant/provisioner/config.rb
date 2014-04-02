
module VagrantPlugins
module CORL
module Config
class CORL < ::Vagrant.plugin("2", :config)

  #-----------------------------------------------------------------------------
  # Constructor / Destructor

  def initialize
    super
    @network_path = UNSET_VALUE
    @network      = UNSET_VALUE
    @node         = UNSET_VALUE
  end
  
  #---
  
  def finalize!
    super
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  attr_accessor :network_path, :network, :node
  
  #-----------------------------------------------------------------------------
  # Validation

  def validate(machine)
    errors = _detected_errors    
    { "CORL provisioner" => errors }
  end
end
end
end
end

