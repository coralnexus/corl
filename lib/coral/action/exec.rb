
module Coral
module Action
class Exec < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Seed action interface
  
  def normalize
    super('coral exec <command> [ <args> ... ]')
    
    codes :network_failure => 20
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.arg_array(:command, nil, 
      'coral.core.actions.exec.options.command'
    )
    node_options(parser)
  end
  
  #---
   
  def execute
    super do |node, network, status|
      if network && node
        command_str = settings[:command].join(' ')
        result      = node.exec({ :commands => [ command_str ] }).first
        status      = result[:status]
      else
        status = code.network_failure
      end
      status
    end
  end
end
end
end
