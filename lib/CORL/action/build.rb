
module CORL
module Action
class Build < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      info('corl.actions.build.start') 
      ensure_node(node) do         
        node.build
      end
    end
  end
end
end
end
