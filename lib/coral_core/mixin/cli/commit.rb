
module Coral
module Mixin
module CLI
module Commit
        
  #-----------------------------------------------------------------------------
  # Options
        
  def commit_options(parser, optional = true)
    if optional
      parser.option_bool(:commit, false, 
        '--commit', 
        'coral.core.mixins.commit.options.commit'
      )
    else
      parser.options[:commit] = true
    end
         
    parser.option_bool(:allow_empty, false,
      '--empty', 
      'coral.core.mixins.commit.options.empty'
    )
    parser.option_bool(:propogate, false,
      '--propogate', 
      'coral.core.mixins.commit.options.propogate'
    )          
    parser.option_str(:message, '',
      '--message COMMIT_MESSAGE',  
      'coral.core.mixins.commit.options.message'
    )
    parser.option_str(:author, nil,
      '--author COMMIT_AUTHOR',  
      'coral.core.mixins.commit.options.author'
    )         
  end
        
  #-----------------------------------------------------------------------------
  # Operations
        
  def commit(project, files = '.')
    success = true
          
    if project && options[:commit]
      success = project.commit(files, {
        :allow_empty => options[:allow_empty],
        :message     => options[:message],
        :author      => options[:author],
        :propogate   => options[:propogate]
      })
    end
    success
  end
end
end
end
end

