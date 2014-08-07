
module Nucleon
module Action
module Node
class Identity < Nucleon.plugin_class(:nucleon, :cloud_action)
 
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :identity, 700)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :identity_upload_failure
      
      register_str :name
      register_project :identity
      register_nodes :identity_nodes      
    end
  end
  
  #---
  
  def ignore
    [ :nodes ]
  end
  
  def arguments
    [ :name, :identity_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |local_node|
      ensure_network do
        builder = network.identity_builder({ settings[:name] => settings[:identity] })
        
        if builder.build(local_node)
          identity_directory = File.join(builder.build_directory, settings[:name])
          
          success = network.batch(settings[:identity_nodes], settings[:node_provider], settings[:parallel]) do |node|
            info('start', { :provider => node.plugin_provider, :name => node.plugin_name })
            
            remote_network_directory  = node.lookup(:corl_network)
            
            remote_config_directory        = File.join(remote_network_directory, network.config_directory.sub(/#{network.directory}#{File::SEPARATOR}/, ''))            
            remote_identity_base_directory = File.join(remote_network_directory, builder.build_directory.sub(/#{network.directory}#{File::SEPARATOR}/, ''))
            remote_identity_directory      = File.join(remote_identity_base_directory, settings[:name])
            
            node.cli.mkdir('-p', remote_identity_base_directory)
            node.cli.rm('-Rf', remote_identity_directory)
            
            if success = node.send_files(identity_directory, remote_identity_directory, nil, '0700')
              dbg('we were successful!')   
            end        
            success        
          end
        end
        myself.status = code.batch_error unless success
      end
    end
  end
end
end
end
end
