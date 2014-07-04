
module Nucleon
module Action
module Cloud
class Machines < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:cloud, :machines, 860)
  end

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :node_load_failure,
            :machine_load_failure
    end
  end
  
  #---
  
  def ignore
    node_ignore - [ :node_provider ]
  end
  
  def arguments
    [ :node_provider ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
  
  def execute
    super do |local_node, network|
      info('corl.actions.machines.start')
      
      ensure_network(network) do
        if node = network.test_node(settings[:node_provider])
          if machine_types = node.machine_types
            machine_types.each do |machine_type|
              info(node.render_machine_type(machine_type), { :prefix => false, :i18n => false })
            end
          
            myself.result = machine_types
            success('corl.actions.machines.results', { :machines => machine_types.length }) if machine_types.length > 1
          else
            myself.status = code.machine_load_failure
          end
        else
          myself.status = code.node_load_failure
        end
      end
    end
  end
end
end
end
end
