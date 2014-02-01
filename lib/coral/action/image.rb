
module Coral
module Action
class Image < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral image')
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.image.start')
      
      status      
    end
  end
end
end
end
