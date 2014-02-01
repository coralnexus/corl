
module Coral
module Action
class Remove < Plugin::Action
  
  include Mixin::Action::Project
  include Mixin::Action::Push

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral remove <subproject/path>') do |parser|
      parser.arg_str(:sub_path, nil, 
        'coral.core.actions.remove.options.sub_path'
      )
      project_options(parser, true, true)
      push_options(parser, true)
    end
  end
  
  #---
   
  def execute
    codes :project_failure => 20,
          :delete_failure  => 21,
          :push_failure    => 22
          
    super do |node, network, status|
      info('coral.core.actions.remove.start')
      
      if project = project_load(Dir.pwd, false)
        if project.delete_subproject(settings[:sub_path])
          status = Coral.code.push_failure unless push(project)
        else
          status = Coral.code.delete_failure
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
