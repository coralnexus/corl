
module CORL
module Action
class Stop < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure,
            :stop_failure
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
      info('corl.actions.stop.start')
      
      if network && node
        unless node.stop
          myself.status = code.stop_failure
        end   
      else
        myself.status = code.network_failure
      end
    end
  end
end
end
end
