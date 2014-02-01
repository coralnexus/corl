
module Coral
module Action
class Lookup < Plugin::Action
 
  #-----------------------------------------------------------------------------
  # Accessors / Modifiers
  
  def usage
    'coral lookup <property>'
  end

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(parser)
    parser.arg_str(:property, nil, 
      'coral.core.actions.create.options.property'
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
