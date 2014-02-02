
module Coral
module Action
class Image < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Image action interface
  
  def normalize
    super('coral image')
  end
 
  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
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
