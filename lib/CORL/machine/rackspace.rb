
module CORL
module Machine
class Rackspace < Fog
 
  #-----------------------------------------------------------------------------
  # Checks
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
 
  #-----------------------------------------------------------------------------
  # Management

  def reload(options = {})
    super do
      config = Config.ensure(options)
      logger.debug("Rebooting Rackspace machine #{name}")
      
      success = server.reboot(config.get(:type, 'SOFT'))
      
      server.wait_for { ready? } if success
      success
    end
  end
end
end
end