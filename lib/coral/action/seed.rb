
module Coral
module Action
class Seed < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Seed action interface
  
  def normalize
    super('coral seed <project:::reference>')    
    
    codes :project_failure      => 20,
          :network_load_failure => 21,
          :node_add_failure     => 22
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_str(:branch, :master, 
      '--branch BRANCH', 
      'coral.core.actions.seed.options.branch'
    )
    parser.arg_str(:reference, nil, 
      'coral.core.actions.create.options.reference'
    )
    node_options(parser)
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.seed.start')
      
      status = admin_exec(status) do
        network_path = lookup(:coral_network)
        
        project = Coral.project(extended_config(:project, {
          :directory => network_path,
          :url       => settings[:reference],
          :revision  => settings[:branch],
          :pull      => true
        }))
        
        if project
          if network.load
            success = network.add_node(node.plugin_provider, node.hostname, {
              :public_ip  => node.public_ip,
              :private_ip => node.private_ip,
              :revision   => project.revision
            })
            status = code.node_add_failure unless success
          else
            status = code.network_load_failure    
          end     
        else
          status = code.project_failure  
        end
        status
      end
    end
  end
end
end
end
