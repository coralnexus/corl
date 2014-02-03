
module Coral
module Action
class Images < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Spawn action interface
  
  def normalize
    super('coral images <node_provider>')
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.images.start')
      
      
      
      status
    end
  end
end
end
end
