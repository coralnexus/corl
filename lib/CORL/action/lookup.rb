
module CORL
module Action
class Lookup < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :property, :str, nil
    end
  end
  
  #---
  
  def arguments
    [ :property ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_node(node) do
        property = settings[:property]
        value    = node.lookup(property)
      
        ui.info(sprintf("#{property} = %s", value.inspect))
      end
    end
  end
end
end
end
