
module Coral
module Action
class Create < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral create [ <project:::reference> ]') do |parser|
      network_path         = lookup(:coral_network)      
      default_project_path = Dir.pwd
      
      if Coral.admin?
        Dir.mkdir(network_path) unless File.directory?(network_path)
        default_project_path = network_path
      end
      
      parser.option_str(:path, default_project_path, 
        '--path PROJECT_DIR', 
        'coral.core.actions.create.options.path'
      )
      parser.option_str(:revision, :master, 
        '--revision REVISION/BRANCH', 
        'coral.core.actions.create.options.revision'
      )
      parser.arg_str(:reference, 
        'github:::coralnexus/puppet-cloud-template', 
        'coral.core.actions.create.options.reference'
      )
    end
  end
  
  #---
   
  def execute
    codes :project_failure => 20
          
    super do |node, network, status|
      info('coral.core.actions.create.start')
      
      project = Coral.project(extended_config(:project, {
        :directory => settings[:path],
        :url       => settings[:reference],
        :revision  => settings[:revision],
        :pull      => true
      }))
      
      project ? status : Coral.code.project_failure
    end
  end
end
end
end
