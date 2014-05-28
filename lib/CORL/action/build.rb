
module CORL
module Action
class Build < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :environment, :str, ''
    end
  end
  
  #---
  
  def arguments
    [ :environment ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node, network|
      info('corl.actions.build.start') 
      ensure_node(node) do
        settings.delete(:environment) if settings[:environment] == ''
        
        if settings.has_key?(:environment)
          node.create_fact(:corl_environment, settings[:environment])
        end 
        
        node.build(settings)
      end
    end
  end
end
end
end
