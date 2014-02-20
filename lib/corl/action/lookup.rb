
module CORL
module Action
class Lookup < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Lookup action interface
  
  def normalize
    super('corl lookup <property>') 
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.arg_str(:property, nil, 
      'corl.core.actions.create.options.property'
    )
  end
  
  #---
   
  def execute
    super do |node, network, status|
      property = settings[:property]
      value    = lookup(property)
      
      ui.success(sprintf("#{property} = %s", value.inspect))                
      status
    end
  end
end
end
end
