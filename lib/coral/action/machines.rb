
module Coral
module Action
class Machines < Plugin::Action

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
      info('coral.actions.machines.start')
      
      if node = network.test_node(settings[:node_provider])
        if machine_types = node.machine_types
          machine_types.each do |machine_type|
            render(node.render_machine_type(machine_type), { :prefix => false })
          end
          
          myself.result = machine_types
          success('coral.actions.machines.results', { :machines => machine_types.length }) if machine_types.length > 1
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
