
module Coral
module Action
class Create < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral create [ <project:::reference> ]') do |parser|
      parser.option_str(:path, Dir.pwd, 
        '--path PROJECT_DIR', 
        'coral.core.actions.create.options.path'
      )
      parser.arg_str(:reference, 
        'github:::coralnexus/puppet-cloud-template', 
        'coral.core.actions.create.options.reference'
      )
    end
  end
  
  #---
   
  def execute
    return super do
      info('coral.core.actions.create.start')
      
      success = false
      project = Coral.project({
        :directory => options[:path],
        :url       => arguments[:reference],
        :pull      => true
      })          
      success = true if project
      success
    end
  end
end
end
end
