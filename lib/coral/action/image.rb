
module Coral
module Action
class Image < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Accessors / Modifiers
  
  def usage
    'coral image'
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
