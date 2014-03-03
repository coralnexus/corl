
module CORL
module Action
class Spawn < Plugin::CloudAction
  
  include Mixin::Action::Keypair
 
  #----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure,
            :key_failure,
            :node_create_failure
      
      register :groups, :array, []      
      register :region, :str, nil
      register :machine_type, :str, nil
      register :image, :str, nil
      register :user, :str, :root     
      register :hostnames, :array, nil
        
      keypair_config
      
      config.defaults(CORL.action_config(:bootstrap))
      config.defaults(CORL.action_config(:seed))
      
      config[:project_reference].default = "github:::coraltech/cluster-test[master]"
    end
  end
  
  #---
  
  def ignore
    node_ignore - [ :parallel, :node_provider ] + [ :bootstrap_nodes ]
  end
  
  def arguments
    [ :node_provider, :image, :hostnames ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
 
  def execute
    super do |node, network|
      info('corl.actions.spawn.start')      
      
      if network
        if keypair && keypair_clean
          results       = []
          node_provider = settings.delete(:node_provider)
          
          settings.delete(:hostnames).each do |hostname|
            if settings[:parallel]
              results << network.future.add_node(node_provider, hostname, settings)
            else
              results << network.add_node(node_provider, hostname, settings)    
            end
          end
          results     = results.map { |future| future.value } if settings[:parallel]                  
          myself.status = code.batch_error if results.include?(false)
        else
          myself.status = code.key_failure  
        end        
      else
        myself.status = code.network_failure    
      end
    end
  end
end
end
end
