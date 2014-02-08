
module Coral
module Action
class Seed < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Seed action interface
  
  def normalize
    super('coral seed <project:::reference>')    
    
    codes :project_failure      => 20,
          :network_load_failure => 21,
          :home_lookup_failure  => 22,
          :no_remote_directory  => 23
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_str(:home_env_var, "HOME", 
      '--home-env ENV_VAR', 
      'coral.core.actions.seed.options.home_env_var'
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
        dbg(node, 'node')
        status = admin_exec(status) do
          network_path = lookup(:coral_network)
          keypair      = Util::SSH.generate
        
          dbg(keypair, 'key pair')
          
          results = node.command(:echo, { :args => '$' + settings[:home_env_var].gsub('$', '') })
          ui.warn(results[:error], { :prefix => false }) unless results[:error].empty?
            
          if results[:status] == code.success
            if ! results[:result].empty?
              ssh_dir = File.join(results[:result], '.ssh')
              dbg(ssh_dir, 'ssh directory')
            else
              status = code.no_ssh_directory  
            end
          else
            status = code.home_lookup_failure
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
