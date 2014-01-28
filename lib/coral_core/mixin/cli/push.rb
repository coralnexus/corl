
module Coral
module Mixin
module CLI
module Push
        
  #-----------------------------------------------------------------------------
  # Options
        
  def push_options(parser, optional = true)
    if optional
      parser.option_bool(:push, false, 
        '--push', 
        'coral.core.mixins.push.options.push'
      )
    else
      parser.options[:push] = true
    end
          
    parser.option_bool(:propogate, false,
      '--propogate', 
      'coral.core.mixins.push.options.propogate'
    )          
    parser.option_str(:remote, :edit,
      '--remote PROJECT_REMOTE',  
      'coral.core.mixins.push.options.remote'
    )
    parser.option_str(:revision, :master,
      '--revision PROJECT_REVISION',  
      'coral.core.mixins.push.options.revision'
    )         
  end
        
  #-----------------------------------------------------------------------------
  # Operations
        
  def push(project, remote = :edit)
    success = true
          
    if project && options[:push]
      success = project.push(options[:remote], extended_config(:push, {
        :revision  => options[:revision],
        :propogate => options[:propogate]
      }))
    end
    success
  end
end
end
end
end

