
module Coral
module Translator
class Yaml < Plugin::Translator
   
  #-----------------------------------------------------------------------------
  # Translator operations
   
  def parse(yaml_text)
    properties = {}
    
    if yaml_text && ! yaml_text.empty?
      properties = Util::Data.parse_yaml(yaml_text)
    end
    return properties
  end
  
  #---
  
  def generate(properties)
    return Util::Data.to_yaml(properties)
  end
end
end
end
