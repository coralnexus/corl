
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
          
          if keys = keypair.store(ssh_dir)
            if project_info = Plugin::Project.translate_reference(settings[:reference], true)
              project_info = Config.new(project_info)
            else
              project_info = Config.new({ :provider => :git })
            end
            
            project = Coral.project(extended_config(:project, {
              :directory => network_path,
              :reference => project_info.get(:reference, nil),
              :url       => project_info.get(:url, settings[:reference]),
              :revision  => project_info.get(:revision, settings[:branch]),
              :create    => true,
              :pull      => true,
              :keys      => keys
            }), project_info[:provider])
        
            if project
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
            else
              status = code.project_failure  
            end            
          else
            status = code.key_store_failure
          end
          status
        end
      end
      status
    end
  end
end
end
end
