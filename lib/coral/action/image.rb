
module Coral
class Codes
  code(:image_failure, 20)
end

#-------------------------------------------------------------------------------
  
module Action
class Image < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral image')
  end
  
  #---
   
  def execute
    return super do |node, network|
      info('coral.core.actions.image.start')
      
      Coral.code.image_failure      
    end
  end
end
end
end
