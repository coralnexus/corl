
module Nucleon
module Action
module Cloud
class Inspect < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:cloud, :inspect, 950)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
 
  def configure
    super do
      register :elements, :array, []
    end
  end
  
  #---
   
  def arguments
    [ :elements ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_network(network) do
        if settings[:elements].empty?
          data = network.config.export
        else
          data = network.config.get(settings[:elements])
        end
        ui.info("\n\n" + CORL.render_object(data) + "\n\n")
      end
    end
  end
end
end
end
end
