
module Coral
module Action
class Add < Plugin::Action
  
  include Mixin::CLI::Project
  include Mixin::CLI::Push

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral add <subproject/path> <subproject:::reference>') do |parser|
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
    return super do
      info('coral.core.actions.add.start')
      
      success = false    
      project = project_load(Dir.pwd, false)
      
      if project
        sub_info = project.translate_reference(arguments[:sub_reference], options[:editable])
        sub_path = arguments[:sub_path]
          
        if sub_info
          sub_url      = sub_info[:url]
          sub_revision = sub_info[:revision]
        else
          sub_url      = arguments[:sub_reference]
          sub_revision = nil
        end
          
        success = project.add_subproject(sub_path, sub_url, sub_revision)
        success = push(project) if success          
      end  
      success
    end
  end
end
end
end
