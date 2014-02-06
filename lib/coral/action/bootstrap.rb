
module Coral
module Action
class Bootstrap < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Seed action interface
  
  def normalize
    super('coral bootstrap <provider> <name>')
    
    codes :network_failure => 20
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.arg_str(:provider, nil, 
      'coral.core.actions.bootstrap.options.provider'
    )
    parser.arg_str(:node_name, nil, 
      'coral.core.actions.bootstrap.options.node_name'
    )
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.bootstrap.start')
      
      if network
        if bootstrap_node = network.node(settings[:provider], settings[:node_name])
          #dbg(bootstrap_node.export, 'node')
          #dbg(bootstrap_node.name)
          #dbg(bootstrap_node.public_ip)
          #dbg(bootstrap_node.private_ip)
          #dbg(bootstrap_node.hostname)
          #dbg(bootstrap_node.private_key)
          #dbg(bootstrap_node.public_key)
          
          bootstrap_path = File.join(Plugin.core.full_gem_path, 'bootstrap')
          
          if bootstrap_path
            dbg(bootstrap_path, 'bootstrap')
          end
          
          results = bootstrap_node.command(:ifconfig, {})
          ui.info(results.stdout, { :prefix => false })
          ui.warn(results.stderr, { :prefix => false })
          status = results.status
        end
      else
        status = code.network_failure
      end
      status
    end
  end
end
end
end
