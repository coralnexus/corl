
module Coral
module Context
class Type < Plugin::Context
   
  #-----------------------------------------------------------------------------
  # Context operations
   
  def filter(plugins)
    type = get(:filter_type)
    
    return plugins unless type
    
    if plugins.has_key?(type)
      return { type => plugins[type] }  
    end
    return {}
  end
end
end
end
