
module Coral
module Template
class YAML < Base
  #-----------------------------------------------------------------------------
  # Renderers  
   
  def render(input)
    return Util::Data.to_yaml(input)    
  end
end
end
end