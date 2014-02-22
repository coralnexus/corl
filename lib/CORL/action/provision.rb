
module CORL
module Action
class Provision < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :provider, :str, :puppetnode
      register :directory, :str, :default
    end
  end
  
  def arguments
    [ :directory ]
  end

  #-----------------------------------------------------------------------------
  # Operations
  
  def execute
    super do |node, network|
      info('corl.actions.provision.start')
      
    end
  end
end
end
end
