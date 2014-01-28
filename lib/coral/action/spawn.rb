
module Coral
module Action
class Spawn < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral spawn <node_reference>') do |parser|
      parser.option_str(:image, nil, 
        '--image IMAGE_NAME', 
        'coral.core.actions.spawn.options.image'
      )
      parser.option_str(:flavor, nil, 
        '--flavor MACHINE_FLAVOR', 
        'coral.core.actions.spawn.options.flavor'
      )
      parser.option_str(:provider, :rackspace,
        '--provider DEFAULT_NODE_PROVIDER', 
        'coral.core.actions.spawn.options.provider'
      )
      parser.arg_str(:node_reference, nil, 
        'coral.core.actions.spawn.options.node_reference'
      ) 
    end
  end
  
  #---
   
  def execute
    return super do
      info('coral.core.actions.spawn.start')
      
      true
    end
  end
end
end
end
