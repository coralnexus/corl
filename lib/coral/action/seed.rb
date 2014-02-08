
module Coral
module Action
class Seed < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Seed action interface
  
  def normalize
    super('coral seed <project:::reference>')    
    
    codes :key_store_failure    => 20,
          :project_failure      => 20,
          :network_load_failure => 21
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    home_dir = ( ENV['USER'] == 'root' ? '/root' : ENV['HOME'] )
        
    parser.option_str(:home, home_dir, 
      '--home USER_HOME_DIR', 
      'coral.core.actions.seed.options.home'
    )
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
      
      if node && network
        status = admin_exec(status) do
          network_path = lookup(:coral_network)
          keypair      = Util::SSH.generate
          ssh_dir      = File.join(settings[:home], '.ssh')
          
          dbg(keypair, 'key pair')
          dbg(ssh_dir)
          
          if keys = keypair.store(ssh_dir)
            dbg(keys, 'keys')
          else
            status = code.key_store_failure
          end          
                  
          #project = Coral.project(extended_config(:project, {
          #  :directory => network_path,
          #  :url       => settings[:reference],
          #  :revision  => settings[:branch],
          #  :pull      => true
          #}))
        
          #if project
          #  if network.load
          #    success = network.add_node(node.plugin_provider, node.hostname, {
          #      :public_ip  => node.public_ip,
          #      :private_ip => node.private_ip,
          #      :revision   => project.revision
          #    })
          #    status = code.node_add_failure unless success
          #  else
          #    status = code.network_load_failure    
          #  end     
          #else
          #  status = code.project_failure  
          #end
          status
        end
      end
      status
    end
  end
end
end
end
