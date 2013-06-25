
module Coral
module Provisioner
  
  #-----------------------------------------------------------------------------
  # Provisioner initialization
  
  @@instances = {}
  
  #---
  
  def self.instance(name, options = {})
    name   = name.to_sym if name
    config = Config.ensure(options)
    
    unless name && @@instances.has_key?(name)
      instance = get(config[:provider]).new(name, config)
      name     = instance.name
      
      @@instances[name] = instance 
    end    
    return @@instances[name]
  end
  
  #---
  
  def self.get(provider = :puppet)
    return Coral.get_class(:provisioner, provider, :puppet)
  end
  
  #-----------------------------------------------------------------------------
  # Extensions
  
  def self.providers
    return Coral.plugins(:provisioner)
  end
  
  #---
  
  def self.load
    providers.each do |name, plugin|
      provisioner = get(name)
      provisioner.load if provisioner
    end
  end

  #-----------------------------------------------------------------------------
  # Base catalog
  
class Base < Config
  # All Catalog classes should directly or indirectly extend Base
  
  def intialize(name, options = {})
    super
    
    @name = name
    normalize
  end
  
  #---
  
  def initialized?(options = {})
    
  end
  
  #---
  
  def method_missing(method, *args, &block)  
    return nil  
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  attr_reader :name
  
  #---
  
  def normalize
  end
  protected :normalize
  
  #---
  
  def load
  end
  protected :load
  
  #---
  
  def hiera_config
  end
  
  #-----------------------------------------------------------------------------
  # Provisioner operations
  
  def lookup(property, default = nil, options = {})
    # Implement in sub classes    
  end
  
  #--
  
  def import(files)
    # Implement in sub classes  
  end
  
  #---
  
  def include(resource_name, properties, options = {})
    # Implement in sub classes  
  end
  
  #---
  
  def provision(options = {})
    # Implement in sub classes   
  end
end
end
end