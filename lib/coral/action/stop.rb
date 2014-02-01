
module Coral
module Action
class Stop < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral stop')
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
