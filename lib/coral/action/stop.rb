
module Coral
module Action
class Stop < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral stop')
  end
  
  #---
   
  def execute
    return super do
      info('coral.core.actions.stop.start')
      
      true
    end
  end
end
end
end
