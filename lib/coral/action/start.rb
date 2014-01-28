
module Coral
module Action
class Start < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral start <node_reference>') do |parser|
      parser.option_str(:provider, :rackspace,
        '--provider DEFAULT_NODE_PROVIDER', 
        'coral.core.actions.start.options.provider'
      )
      parser.arg_str(:node_reference, nil, 
        'coral.core.actions.start.options.node_reference'
      )
    end
  end
  
  #---
   
  def execute
    return super do
      info('coral.core.actions.start.start')
      
      true
    end
  end
end
end
end
