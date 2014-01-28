
module Coral
module Mixin
module CLI
module Project
        
  #-----------------------------------------------------------------------------
  # Options
        
  def project_options(parser, ref_override = false, rev_override = false)
    parser.option_str(:project_provider, 'git', 
      '--proj-provider PROVIDER', 
      'coral.core.mixins.project.options.provider'
    )
    if ref_override
      parser.option_str(:reference, nil,
        '--reference PROJECT_REF', 
        'coral.core.mixins.project.options.reference'
      )
    end
    if rev_override
      parser.option_str(:revision, nil,
        '--revision PROJECT_REV',  
        'coral.core.mixins.project.options.revision'
      )
    end
  end
        
  #-----------------------------------------------------------------------------
  # Operations
        
  def project_load(root_dir, update = false)
        
    # 1. Set a default project provider (reference can override)
    # 2. Get project from root directory
    # 3. Initialize project if not yet initialized
    # 4. Set remote if needed
    # 5. Checkout revision if needed
    # 6. Pull down updates if requested
          
    return Coral.project(extended_config(:project, {
      :provider  => options[:project_provider],
      :directory => root_dir,
      :url       => options[:reference],
      :revision  => options[:revision],
      :pull      => update
    }))
  end       
end
end
end
end

