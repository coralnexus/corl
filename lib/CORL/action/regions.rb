
module CORL
module Action
class Regions < Plugin::CloudAction

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :node_load_failure,
            :region_load_failure
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
      info('corl.actions.regions.start')
      
      ensure_network(network) do
        if node = network.test_node(settings[:node_provider])
          if regions = node.regions
            regions.each do |region|
              render(sprintf("> %s", region), { :prefix => false })
            end
          
            myself.result = regions
            success('corl.actions.regions.results', { :regions => regions.length }) if regions.length > 1
          else
            myself.status = code.region_load_failure
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
