
module Nucleon
module Action
module Cloud
class Create < Nucleon.plugin_class(:nucleon, :cloud_action)

  include Mixin::Action::Project
 
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:cloud, :create, 1000)
  end
  
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do    
      config.defaults(CORL.action_config(:project_create))      
      config[:project_reference].default = 'github:::coralnexus/network-template'
    end
  end
  
  #---
  
  def arguments
    [ :project_reference ]
  end
 
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super(false) do
      info('nucleon.action.cloud.create.start')
      
      project       = project_load(settings[:path], true, true)
      myself.status = code.project_failure unless project
      
      if project.remote(:origin) =~ /coralnexus\/network\-template/
        project.delete_remote(:origin)
        project.delete_remote(:edit)
      end
    end
  end
end
end
end
end
