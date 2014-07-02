
module Nucleon
module Action
module Node
class Facts < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :facts, 570)
  end
  
  #----
  
  def prepare
    CORL.quiet = true
    super    
  end
 
  #-----------------------------------------------------------------------------
  # Settings

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_node(node) do
        facter_facts = node.facts
        
        puts Util::Data.to_json(facter_facts, true)        
        myself.result = facter_facts
      end
    end
  end
end
end
end
end
