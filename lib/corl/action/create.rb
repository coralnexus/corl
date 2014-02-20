
module CORL
module Action
class Create < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Create action interface
  
  def normalize
    super('corl create [ <project:::reference> ]')    
    
    codes :project_failure => 20
  end
 
  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    network_path = Dir.pwd     
    network_path = lookup(:corl_network) if CORL.admin?
      
    parser.option_str(:path, network_path, 
      '--path PROJECT_DIR', 
      'corl.core.actions.create.options.path'
    )
    parser.option_str(:revision, :master, 
      '--revision REVISION/BRANCH', 
      'corl.core.actions.create.options.revision'
    )
    parser.arg_str(:reference, 
      'github:::coralnexus/puppet-cloud-template', 
      'corl.core.actions.create.options.reference'
    )
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('corl.core.actions.create.start')
      
      project = CORL.project(extended_config(:project, {
        :create    => true,
        :directory => settings[:path],
        :url       => settings[:reference],
        :revision  => settings[:revision],
        :pull      => true
      }))
      
      project ? status : code.project_failure
    end
  end
end
end
end
