
module Coral
module Action
class Update < Plugin::Action
  
  include Mixin::Action::Project
  
  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral update') do |parser|
      project_options(parser, true, true)
    end
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.update.start')
      
      project = project_load(Dir.pwd, true)
      status  = Coral.code.project_failure unless project
      status
    end
  end
end
end
end
