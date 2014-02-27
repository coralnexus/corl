
module CORL
module Action
class Destroy < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure,
            :destroy_failure
    end
  end
  
  #---
  
  def arguments
    [ :nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      info('corl.actions.destroy.start')
      
      if network && node
        unless node.destroy(settings)
          myself.status = code.destroy_failure
        end
      else
        myself.status = code.network_failure
      end
    end
  end
end
end
end
