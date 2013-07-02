
module Coral
module Template
class YAML < Plugin::Template
  
  #-----------------------------------------------------------------------------
  # Renderers  
   
  def render_processed(data)
    return Util::Data.to_yaml(data)    
  end
end
end
end