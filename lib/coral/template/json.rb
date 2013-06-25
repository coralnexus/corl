
module Coral
module Template
class JSON < Base
  #-----------------------------------------------------------------------------
  # Renderers  
   
  def render(input)
    return Util::Data.to_json(input)    
  end
end
end
end