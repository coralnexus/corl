
module CORL
module Action
class Facts < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      ensure_node(node) do
        facter_facts = Config.facts
      
        ui.info(Util::Data.to_json(facter_facts, true), { :prefix => false })
        myself.result = facter_facts
      end
    end
  end
end
end
end
