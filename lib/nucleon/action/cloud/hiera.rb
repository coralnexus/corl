
module Nucleon
module Action
module Cloud
class Hiera < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:cloud, :hiera, 925)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
 
  def configure
    super do
      register :properties, :array, []
      config.defaults(CORL.action_config(:node_lookup))  
    end
  end
  
  #---
  
  def ignore
    [ :property ]
  end
   
  def arguments
    [ :properties ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_node(node) do
        if settings[:properties].empty?
          $stderr.puts Util::Data.to_json(node.hiera_configuration(node.facts), true)
        else
          settings.delete(:properties).each do |property|
            ui_group(property) do
              $stderr.puts Util::Data.to_json(node.lookup(property, nil, settings), true)
            end
          end  
        end      
      end
    end
  end
end
end
end
end
