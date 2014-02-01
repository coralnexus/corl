
module Coral
module Action
class Clone < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral clone <existing_node_reference> <new_node_reference>') do |parser|
      parser.option_str(:provider, :rackspace,
        '--provider DEFAULT_NODE_PROVIDER', 
        'coral.core.actions.start.options.provider'
      )
      parser.arg_str(:existing_node_reference, nil, 
        'coral.core.actions.start.options.existing_node_reference'
      )
      parser.arg_str(:new_node_reference, nil, 
        'coral.core.actions.start.options.new_node_reference'
      )
    end
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.clone.start')
      
      status
    end
  end
end
end
end
