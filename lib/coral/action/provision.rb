
module Coral
module Action
class Provision < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral provision [ <project_directory> ]') do |parser|
      parser.option_str(:provider, nil, 
        '--provider PROVISIONER_PROVIDER', 
        'coral.core.actions.provision.options.provider'
      )
      parser.arg_str(:directory, :default, 
        'coral.core.actions.provision.options.directory'
      ) 
    end
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.provision.start')
      
      status
    end
  end
end
end
end
