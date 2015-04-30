
module CORL
module Node
class Raspberrypi < Nucleon.plugin_class(:CORL, :node)

  #-----------------------------------------------------------------------------
  # Node plugin interface

  def normalize(reload)
    super
    myself.machine = create_machine(:machine, :raspberrypi, machine_config)
  end

  #-----------------------------------------------------------------------------
  # Checks

  #-----------------------------------------------------------------------------
  # Property accessors / modifiers

  #-----------------------------------------------------------------------------
  # Utilities

end
end
end
