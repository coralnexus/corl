
module Coral
module Action
class Seed < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Accessors / Modifiers
  
  def usage
    'coral seed <project:::reference>'
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.option_str(:branch, :master, 
      '--branch BRANCH', 
      'coral.core.actions.seed.options.branch'
    )
    parser.arg_str(:reference, nil, 
      'coral.core.actions.create.options.reference'
    )
  end
  
  #---
   
  def execute
    codes :project_failure => 20
    
    super do |node, network, status|
      info('coral.core.actions.seed.start')
      
      status = admin_exec(status) do
        network_path = lookup(:coral_network)
        Dir.mkdir(network_path) unless File.directory?(network_path)
      
        project = Coral.project(extended_config(:project, {
          :directory => network_path,
          :url       => settings[:reference],
          :revision  => settings[:branch],
          :pull      => true
        }))
        
        if project
          if node.nil?
            # Register this machine with the network
          end          
        else
          status = code.project_failure  
        end
      end
                
      status
    end
  end
end
end
end
