
module Nucleon
module Action
module Cloud
class Inspect < CORL.plugin_class(:nucleon, :cloud_action)
  
  include Mixin::Action::Registration
  
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
      register_translator :format, :json
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
        
        translator = CORL.translator({}, settings[:format])
        $stderr.puts translator.generate(data)
      end
    end
  end
end
end
end
end
