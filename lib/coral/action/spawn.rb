
module Coral
class Codes
  code(:spawn_failure, 20)
end

module Action
class Spawn < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral spawn <node_reference>') do |parser|
      parser.option_str(:image, nil, 
        '--image IMAGE_NAME', 
        'coral.core.actions.spawn.options.image'
      )
      parser.option_str(:flavor, nil, 
        '--flavor MACHINE_FLAVOR', 
        'coral.core.actions.spawn.options.flavor'
      )
      parser.arg_str(:node_reference, nil, 
        'coral.core.actions.spawn.options.node_reference'
      ) 
    end
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.spawn.start')
      
      status
    end
  end
end
end
end
