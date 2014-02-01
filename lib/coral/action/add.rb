
module Coral
module Action
class Add < Plugin::Action
  
  include Mixin::Action::Project
  include Mixin::Action::Push

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral add <subproject/path> <subproject:::reference>') do |parser|
      parser.arg_str(:sub_path, nil, 
        'coral.core.actions.add.options.sub_path'
      )
      parser.arg_str(:sub_reference, nil, 
        'coral.core.actions.add.options.sub_reference'
      )
      parser.option_bool(:editable, false, 
        '--editable', 
        'coral.core.actions.add.options.editable'
      )
      project_options(parser, true, true)
      push_options(parser, true)
    end
  end
  
  #---
   
  def execute
    codes :project_failure => 20,
          :add_failure     => 21,
          :push_failure    => 22
    
    super do |node, network, status|
      info('coral.core.actions.add.start')
      
      if project = project_load(Dir.pwd, false)
        sub_info = project.translate_reference(settings[:sub_reference], settings[:editable])
        sub_path = settings[:sub_path]
          
        if sub_info
          sub_url      = sub_info[:url]
          sub_revision = sub_info[:revision]
        else
          sub_url      = settings[:sub_reference]
          sub_revision = nil
        end
          
        if project.add_subproject(sub_path, sub_url, sub_revision)
          status = Coral.code.push_failure unless push(project)
        else
          status = Coral.code.add_failure
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
