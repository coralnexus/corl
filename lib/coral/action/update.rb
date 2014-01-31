
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
    super(args, 'coral update') do |parser|
      project_options(parser, true, true)
    end
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.update.start')
      
      project = project_load(Dir.pwd, true)
          
      status = Coral.code.update_failure unless project
      status
    end
  end
end
end
end
