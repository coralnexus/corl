
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
      
      # Extra settings (TODO)
      # 1. bootstrap path
      # 2. remote home environment variable
      # 3. gateway bootstrap shell script
      
      if network
        if bootstrap_node = network.node(settings[:provider], settings[:node_name])
          bootstrap_path = File.join(Plugin.core.full_gem_path, 'bootstrap')
          
          if File.directory?(bootstrap_path)
            results = bootstrap_node.command(:echo, { :args => "$HOME" })
          
            ui.warn(results[:error], { :prefix => false }) unless results[:error].empty?
            
            if results[:status] == code.success
              if ! results[:result].empty?
                remote_dir = File.join(results[:result], 'bootstrap')
              
                bootstrap_node.command(:rm, { :flags => [ 'R', 'f' ], :args => remote_dir })
          
                if bootstrap_node.upload(bootstrap_path, remote_dir)
                  gateway_script = 'bootstrap.sh'
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
