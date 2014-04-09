
module CORL
module Action
class Reboot < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      info('corl.actions.reboot.start') 
      ensure_node(node) do         
        node.reload
      end
    end
  end
end
end
end
