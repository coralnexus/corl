
module Coral
module Mixins
module ConfigCollection
  #-----------------------------------------------------------------------------
  # Configuration collection interface
  
  def self.all_properties
    return Config::Collection.all
  end
  
  #---
  
  def self.get_property(name)
    return Config::Collection.get(name)
  end
  
  #---
  
  def self.set_property(name, value)
    Config::Collection.set(name, value)
    return self  
  end
  
  #---
  
  def self.delete_property(name)
    Config::Collection.delete(name)
    return self
  end
  
  #---
  
  def self.clear_properties
    Config::Collection.clear
    return self  
  end
  
  #---
  
  def self.save_properties
    Config::Collection.save
    return self
  end
end
end
end
