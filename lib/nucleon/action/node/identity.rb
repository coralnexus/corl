
module Nucleon
module Action
module Node
class Identity < CORL.plugin_class(:nucleon, :cloud_action)
  
  include Mixin::Action::Registration
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :identity, 700)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :name, :str
      register_project :identity
      register_nodes :identity      
    end
  end
  
  #---
  
  def ignore
    [ :nodes ]
  end
  
  def arguments
    [ :name, :identity_project, :identity_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |local_node, network|
      ensure_network(network) do
        batch_success = false
        
        batch_success = network.batch(settings[:identity_nodes], settings[:node_provider], settings[:parallel]) do |node|
          info('corl.actions.identity.start', { :provider => node.plugin_provider, :name => node.plugin_name })
                    
          success = network.identity_builder.build(node, { settings[:name] => settings[:identity_project] })
          success        
        end
        myself.status = code.batch_error unless batch_success
      end
    end
  end
end
end
end
end
