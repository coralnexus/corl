
module Coral
module Action
class Stop < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Stop action interface
  
  def normalize
    super('coral stop')
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.stop.start')
      
      status
    end
  end
end
end
end
