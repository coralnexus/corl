
module Coral
module Translator
class Json < Plugin::Translator
   
  #-----------------------------------------------------------------------------
  # Translator operations
   
  def parse(json_text, options = {})
    config     = Config.ensure(options)
    properties = {}
    
    if json_text && ! json_text.empty?
      properties = Util::Data.parse_json(json_text)
    end
    return properties
  end
  
  #---
  
  def generate(properties, options = {})
    config = Config.ensure(options)
    return Util::Data.to_json(properties, config.get(:pretty, true))
  end
end
end
end
