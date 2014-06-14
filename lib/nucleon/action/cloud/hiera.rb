
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
          ui.info("\n" + CORL.render_object(node.hiera_configuration) + "\n\n", { :prefix => false })
        else
          settings.delete(:properties).each do |property|
            value = Util::Data.to_json(node.lookup(property, nil, settings), true)
            
            ui_group(property) do
              if value.match(/\n/)      
                ui.info("\n\n#{value}\n\n")
              else
                ui.info(value)  
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
end
