
module CORL
module Action
class Build < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure
    end
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      if network && node
        info('corl.actions.build.start')  
        node.build
      else
        myself.status = code.network_failure
      end
    end
  end
end
end
end
