
module Coral
module Template
class Yaml < Plugin::Template
  
  #-----------------------------------------------------------------------------
  # Renderers  
   
  def render_processed(data)
    return Util::Data.to_yaml(data)    
  end
end
end
end