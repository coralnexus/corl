
module Coral
module Action
class Seed < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral seed <project:::reference>') do |parser|
      parser.option_str(:revision, :master, 
        '--branch BRANCH', 
        'coral.core.actions.seed.options.branch'
      )
      parser.arg_str(:reference, nil, 
        'coral.core.actions.create.options.reference'
      )
    end
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.seed.start')
      
      network_path = lookup(:coral_network)
      dbg(network_path, 'network path')
      
      #project = Coral.project(extended_config(:project, {
      #  :directory => options[:path],
      #  :url       => arguments[:reference],
      #  :revision  => options[:revision],
      #  :pull      => true
      #}))
      #project ? true : false
      
      status
    end
  end
end
end
end
