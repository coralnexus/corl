
module Coral
module Template
class Json < Plugin::Template
  
  #-----------------------------------------------------------------------------
  # Renderers  
   
  def render_processed(data)
    return Util::Data.to_json(data)    
  end
end
end
end