
module CORL
module Action
class Start < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Start action interface
  
  def normalize
    super('corl start <node_reference>')
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_str(:provider, :rackspace,
      '--provider DEFAULT_NODE_PROVIDER', 
      'corl.core.actions.start.options.provider'
    )
    parser.arg_str(:node_reference, nil, 
      'corl.core.actions.start.options.node_reference'
    )
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('corl.core.actions.start.start')
      
      status
    end
  end
end
end
end
