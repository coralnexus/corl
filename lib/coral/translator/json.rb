
module Coral
module Translator
class Json < Plugin::Translator
   
  #-----------------------------------------------------------------------------
  # Translator operations
   
  def parse(json_text)
    properties = {}
    
    if json_text && ! json_text.empty?
      properties = Util::Data.parse_json(json_text)
    end
    return properties
  end
  
  #---
  
  def generate(properties)
    return Util::Data.to_json(properties, get(:pretty, true))
  end
end
end
end
