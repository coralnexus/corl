
module Coral
module Action
class Image < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral image')
  end
  
  #---
   
  def execute
    return super do
      info('coral.core.actions.image.start')
      
      true
    end
  end
end
end
end
