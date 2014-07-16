
module Nucleon
module Action
module Cloud
class Regions < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:cloud, :regions, 855)
  end

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :node_load_failure,
            :region_load_failure
    end
    
    config[:node_provider].default = nil
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
    super do |local_node|
      info('start')
      
      ensure_network do
        if node = network.test_node(settings[:node_provider])
          if regions = node.regions
            regions.each do |region|
              info(sprintf("> %s", region), { :prefix => false, :i18n => false })
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
end
