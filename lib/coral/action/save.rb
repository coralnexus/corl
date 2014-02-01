
module Coral
class Codes
  code(:commit_failure, 20)
  code(:push_failure, 21)      
end
  
module Action
class Save < Plugin::Action
  
  include Mixin::Action::Project
  include Mixin::Action::Commit
  include Mixin::Action::Push

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral save [ <file> ... ]') do |parser|
      parser.arg_array(:files, '.', 
        'coral.core.actions.save.options.files'
      )
      project_options(parser, true, false)
      commit_options(parser, false)
      push_options(parser, true)
    end
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.save.start')
          
      if project = project_load(Dir.pwd, false)
        if commit(project, arguments[:files])
          status = Coral.code.push_failure unless push(project)
        else
          status = Coral.code.commit_failure
        end
      else
        status = Coral.code.project_failure
      end
      status
    end
  end
end
end
end
