
module CORL
module Action
class Clone < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Clone action interface
  
  def normalize
    super('corl clone <existing_node_reference> <new_node_reference>')    
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_str(:provider, :rackspace,
      '--provider DEFAULT_NODE_PROVIDER', 
      'corl.core.actions.start.options.provider'
    )
    parser.arg_str(:existing_node_reference, nil, 
      'corl.core.actions.start.options.existing_node_reference'
    )
    parser.arg_str(:new_node_reference, nil, 
      'corl.core.actions.start.options.new_node_reference'
    )
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('corl.core.actions.clone.start')
      
      status
    end
  end
end
end
end
