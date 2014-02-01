
module Coral
module Action
class Update < Plugin::Action
  
  include Mixin::Action::Project
 
  #-----------------------------------------------------------------------------
  # Accessors / Modifiers
  
  def usage
    'coral update'
  end
  
  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    project_options(parser, true, true)
  end
  
  #---
   
  def execute
    codes :project_failure => 20
    
    super do |node, network, status|
      info('coral.core.actions.update.start')
      
      project = project_load(Dir.pwd, true)
      status  = code.project_failure unless project
      status
    end
  end
end
end
end
