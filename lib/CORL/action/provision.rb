
module CORL
module Action
class Provision < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Provision action interface
  
  def normalize
    super('corl provision [ <project_directory> ]')
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_str(:provider, nil, 
      '--provider PROVISIONER_PROVIDER', 
      'corl.core.actions.provision.options.provider'
    )
    parser.arg_str(:directory, :default, 
      'corl.core.actions.provision.options.directory'
    )
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('corl.core.actions.provision.start')
      
      status
    end
  end
end
end
end
