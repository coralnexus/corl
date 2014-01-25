
module Coral
module Action
class Deploy < Plugin::Action
  
  include Mixin::CLI::Project

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    return super(args, 'coral deploy <node_provider> [ <node_name> ... ]') do |parser|
      parser.arg_str(:node_provider, :rackspace, 
        'coral.core.actions.deploy.options.node_provider'
      )
      parser.arg_array(:node_names, [], 
        'coral.core.actions.deploy.options.node_names'
      )
      project_options(parser, false, false)
    end
  end
  
  #---
   
  def execute
    return super do
      info('coral.core.actions.deploy.start')
      
      success = false
      project = project_load(Dir.pwd, false)
      
      if project          
        node_provider = arguments[:node_provider]
        node_names    = arguments[:node_names]

        Coral.vagrant.nodes(arguments[:node_provider]).each do |node_name, node|
          if node_names.empty? || node_names.include?(node_name)
            info('coral.core.actions.deploy.cloud.start',
              :node_name     => node.name,
              :node_provider => node.plugin_provider
            )
                
               
          end            
        end  
      end
      success
    end
  end
end
end
end
