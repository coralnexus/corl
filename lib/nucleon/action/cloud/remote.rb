
module Nucleon
module Action
module Cloud
class Remote < CORL.plugin_class(:nucleon, :cloud_action)
 
  include Mixin::Action::Project
  include Mixin::Action::Push
   
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super([ :cloud ], :remote, 980)
  end
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :project_failure, :push_failure
      
      project_config
      push_config
    end
  end
  
  #---
  
  def ignore
    node_ignore + [ :propogate_push, :pull, :push, :net_remote ]
  end
  
  def arguments
    [ :project_reference ]
  end
  
  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |node|
      ensure_network do
        info('start')
        
        settings[:pull] = false
        settings[:push] = true
                  
        if project = project_load(network.directory, false, false)
          provider = settings[:project_provider]
          
          if settings[:project_reference].match(/^\s*([a-zA-Z0-9_-]+):::(.*)\s*$/)
            provider = $1
          end
          
          Nucleon::Plugin::Project.store_provider(project.directory, provider)
          myself.status = code.push_failure unless push(project)
        else
          myself.status = code.project_failure
        end
      end
    end
  end
end
end
end
end
