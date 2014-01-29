
module Coral
module Action
class Image < Plugin::Action
  
  include Mixin::CLI::Node

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral image') do |parser|
      node_options(parser)
    end
  end
  
  #---
   
  def execute
    return super do
      info('coral.core.actions.image.start')
      
      node_exec do
        
        true  
      end
    end
  end
end
end
end
