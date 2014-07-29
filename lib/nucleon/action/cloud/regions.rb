
module Nucleon
module Action
module Cloud
class Regions < Nucleon.plugin_class(:nucleon, :cloud_action)
  
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
  end
  
  def node_config
    super
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
      ensure_network do
        if node = network.test_node(settings[:node_provider])
          if regions = node.regions
            region_info = node.region_info            
            max_length  = regions.collect {|value| value.length }.sort.pop
            
            regions.each do |region|
              prefixed_message(:info, '  ', sprintf("%-#{max_length + 10}s  %s", purple(region), yellow(region_info[region.to_sym])), { :i18n => false, :prefix => false })
            end
          
            myself.result = regions
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
