
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
      info('coral.core.actions.exec.start')
      
      dbg(node, 'node')
      dbg(network, 'network')
      
      if network && node
        dbg(node.export, 'node')
        dbg(node.name)
        dbg(node.public_ip)
        dbg(node.private_ip)
        dbg(node.hostname)
        dbg(node.private_key)
        dbg(node.public_key)
         
        #results = node.exec({ :commands => [ settings[:command].join(' ') ] }).first
        #ui.info(results.stdout, { :prefix => false })
        #ui.warn(results.stderr, { :prefix => false })
        #status = results.status
      else
        status = code.network_failure
      end
      status
    end
  end
end
end
end
