
module Coral
module Mixins
module ConfigOptions
  #-----------------------------------------------------------------------------
  # Configuration options interface
  
  def self.contexts(contexts = [], hierarchy = [])
    return Config::Options.contexts(contexts, hierarchy)  
  end
  
  #---
  
  def self.get_options(contexts, force = true)
    return Config::Options.get(contexts, force)  
  end
  
  #---
  
  def self.set_options(contexts, options, force = true)
    Config::Options.set(contexts, options, force)
    return self  
  end
  
  #---
  
  def self.clear_options(contexts)
    Config::Options.clear(contexts)
    return self  
  end
end
end
end
