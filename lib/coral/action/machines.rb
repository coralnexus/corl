
module Coral
module Action
class Machines < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Machines action interface
  
  def normalize
    super('coral machines <node_provider>')
    
    codes :node_load_failure  => 20,
          :machine_load_failure => 21
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.arg_str(:provider, nil, 
      'coral.core.actions.machines.options.provider'
    )
  end
  
  #---
   
  def execute
    super do |node, network, status|
      info('coral.core.actions.machines.start')
      
      if node = Coral.node(:test, {}, settings[:provider])
        if machine_types = node.machine_types
          machine_types.each do |machine_type|
            render(node.render_machine_type(machine_type), { :prefix => false })
          end
          
          self.result = machine_types
          success('coral.core.actions.machines.results', { :machines => machine_types.length }) if machine_types.length > 1
        else
          status = code.machine_load_failure
        end
      else
        status = code.node_load_failure
      end
      status
    end
  end
end
end
end
