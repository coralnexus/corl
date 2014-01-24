
module Coral
module Action
class Update < Plugin::Action
  
  include Mixin::CLI::Project
  
  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral update') do |parser|
      project_options(parser, true, true)
    end
  end
  
  #---
   
  def execute
    return super do
      info('coral.core.actions.update.start')
      
      success = false    
      project = project_load(Dir.pwd, true)
          
      success = true if project
      success
    end
  end
end
end
end
