
module Coral
module Action
class Bootstrap < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Seed action interface
  
  def normalize
    super('coral bootstrap <provider> <name>')
    
    codes :network_failure        => 20,
          :bootstrap_path_failure => 21,
          :home_lookup_failure    => 22,
          :no_remote_directory    => 23,
          :upload_failure         => 24,
          :bootstrap_exec_failure => 25
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_str(:bootstrap, File.join(Plugin.core.full_gem_path, 'bootstrap'), 
      '--bootstrap BOOTSTRAP_PROJ_PATH', 
      'coral.core.actions.bootstrap.options.bootstrap'
    )
    parser.option_str(:gateway, 'bootstrap.sh', 
      '--gateway BOOTSTRAP_SCRIPT', 
      'coral.core.actions.bootstrap.options.gateway'
    )
    parser.option_str(:home_env_var, "HOME", 
      '--home-env ENV_VAR', 
      'coral.core.actions.bootstrap.options.home_env_var'
    )
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
          bootstrap_path = settings[:bootstrap]
          
          if File.directory?(bootstrap_path)
            results = bootstrap_node.command(:echo, { :args => '$' + settings[:home_env_var].gsub('$', '') })
          
            ui.warn(results[:error], { :prefix => false }) unless results[:error].empty?
            
            if results[:status] == code.success
              if ! results[:result].empty?
                remote_dir = File.join(results[:result], 'bootstrap')
              
                bootstrap_node.command(:rm, { :flags => [ 'R', 'f' ], :args => remote_dir })
          
                if bootstrap_node.upload(bootstrap_path, remote_dir)
                  gateway_script = settings[:gateway]
                  remote_script  = File.join(remote_dir, gateway_script)                  
                  results        = bootstrap_node.command(remote_script)
                  
                  render(results[:result], { :prefix => false })
                  
                  if results[:status] == code.success
                    success('coral.core.actions.bootstrap.success')
                  else
                    warn('coral.core.actions.bootstrap.error', { :status => results[:status] })
                    status = code.bootstrap_exec_failure
                  end
                else
                  status = code.upload_failure
                end
              else
                status = code.no_remote_directory
              end
            else
              status = code.home_lookup_failure
            end
          else
            status = code.bootstrap_path_failure
          end
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
