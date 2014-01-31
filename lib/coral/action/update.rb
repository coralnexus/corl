
module Coral
class Codes
  code(:update_failure, 20)
end

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
    return super do |node, network|
      info('coral.core.actions.update.start')
      
      status  = Coral.code.success      
      project = project_load(Dir.pwd, true)
          
      status = Coral.code.update_failure unless project
      status
    end
  end
end
end
end
