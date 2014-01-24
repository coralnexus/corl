
module Coral
module Action
class Save < Plugin::Action
  
  include Mixin::CLI::Project
  include Mixin::CLI::Commit
  include Mixin::CLI::Push

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral save [ <file> ... ]') do |parser|
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
    return super do
      info('coral.core.actions.save.start')
          
      project = project_load(Dir.pwd, false)
      
      if project    
        success = commit(project, arguments[:files])
        success = push(project) if success
      end
      success
    end
  end
end
end
end
