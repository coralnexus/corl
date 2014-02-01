
module Coral
module Action
class Start < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Accessors / Modifiers
  
  def usage
    'coral start <node_reference>'
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_str(:provider, :rackspace,
      '--provider DEFAULT_NODE_PROVIDER', 
      'coral.core.actions.start.options.provider'
    )
    parser.arg_str(:node_reference, nil, 
      'coral.core.actions.start.options.node_reference'
    )
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.start.start')
      
      status
    end
  end
end
end
end
