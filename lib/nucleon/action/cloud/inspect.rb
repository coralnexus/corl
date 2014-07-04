
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
        $stderr.puts Util::Data.to_json(data, true)
      end
    end
  end
end
end
end
end
