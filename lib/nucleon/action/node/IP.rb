
module Nucleon
module Action
module Node
class IP < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :ip, 575)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_node(node) do
        ui.info(CORL.public_ip)
      end
    end
  end
end
end
end
end
