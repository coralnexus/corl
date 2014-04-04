
module CORL
module Action
class Ip < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_node(node, network) do
        ui.info(CORL.public_ip)
      end
    end
  end
end
end
end
