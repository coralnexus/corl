
module Coral
module Action
class Remove < Plugin::Action
  
  include Mixin::CLI::Project
  include Mixin::CLI::Push

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral remove <subproject/path>') do |parser|
      parser.arg_str(:sub_path, nil, 
        'coral.core.actions.remove.options.sub_path'
      )
      project_options(parser, true, true)
      push_options(parser, true)
    end
  end
  
  #---
   
  def execute
    return super do
      info('coral.core.actions.remove.start')
      
      success = false    
      project = project_load(Dir.pwd, false)
     
      if project     
        success = project.delete_subproject(arguments[:sub_path])
        success = push(project) if success
      end
      success
    end
  end
end
end
end
