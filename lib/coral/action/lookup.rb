
module Coral
module Action
class Lookup < Plugin::Action

  #-----------------------------------------------------------------------------
  # Action operations
  
  def parse(args)
    super(args, 'coral lookup <property>') do |parser|
      parser.arg_str(:property, nil, 
        'coral.core.actions.create.options.property'
      )
    end
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
