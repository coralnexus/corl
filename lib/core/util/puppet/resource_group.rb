
module CORL
module Util
module Puppet
class ResourceGroup < Core
  
  include Mixin::SubConfig
   
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(type_info, default = {})
    super({
      :info    => hash(type_info),
      :default => symbol_map(hash(default))
    })
    self.resources = {}
  end
     
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def info(default = {})
    return hash(_get(:info, default))
  end
  
  #---
  
  def info=info
    _set(:info, hash(info))
  end
  
  #---
  
  def default(default = {})
    return hash(_get(:default, default))
  end
  
  #---
  
  def default=default
    _set(:default, symbol_map(hash(default)))
  end
 
  #---
  
  def resources(default = {})
    return hash(_get(:resources, default))
  end
  
  #---
  
  def resources=resources
    _set(:resources, symbol_map(hash(resources)))
  end
 
  #---
  
  def composite_resources(default = {})
    return hash(_get(:composite_resources, default))
  end
  
  #---
  
  def composite_resources=resources
    _set(:composite_resources, symbol_map(hash(resources)))
  end
  
  #---
  
  def add(resources, options = {})
    config    = Config.ensure(options)
    resources = normalize(info[:name], resources, config)
    
    unless Util::Data.empty?(resources)
      collection = self.resources
      resources.each do |title, resource|
        Util::Puppet.add_resource(info, title, Config.ensure(resource).export, config)
        collection[title] = resource
      end
      self.resources = collection
    end
    dbg(collection, info[:name])
    return self
  end
  
  #---
  
  def add_composite_resource(name, resource_names)
    composite       = self.composite_resources    
    composite[name] = [] unless composite[name].is_a?(Array)
    
    unless resource_names.is_a?(Array)
      resource_names = [ resource_names ]
    end
    
    resource_names.each do |r_name|
      unless composite[name].include?(r_name)
        composite[name] << r_name
      end
    end
    
    self.composite_resources = composite
  end
  protected :add_composite_resource

  #-----------------------------------------------------------------------------
  # Resource operations
  
  def normalize(type_name, resources, options = {})
    self.composite_resources = {}
    
    config    = Config.ensure(options)
    resources = Util::Data.value(resources)
    
    unless Util::Data.empty?(resources)
      resources.keys.each do |name|
        if ! resources[name] || resources[name].empty? || ! resources[name].is_a?(Hash)        
          resources.delete(name)
        else
          normalize = true
          
          namevar = Util::Puppet.namevar(type_name, name)
          if resources[name].has_key?(namevar)
            value = resources[name][namevar]
            if Util::Data.empty?(value)
              resources.delete(name)
              normalize = false
              
            elsif value.is_a?(Array)
              value.each do |item|
                item_name = "#{name}_#{item}".gsub(/\-/, '_')
                
                new_resource = resources[name].clone
                new_resource[namevar] = item
                
                resources[item_name] = Util::Puppet::Resource.render(new_resource, config)
                add_composite_resource(name, item_name)
              end
              resources.delete(name)
              normalize = false
            end  
          end
          
          if normalize
            resource = Util::Puppet::Resource.new(info, name, resources[name])
            resource.defaults(default, config.import({ :groups => self.composite_resources }))
            
            resources[name] = resource
          end
        end
      end
    end
    return translate(resources, config)
  end
  protected :normalize
  
  #---
  
  def translate(resources, options = {})
    config  = Config.ensure(options)
    results = {}
        
    prefix   = config.get(:resource_prefix, '')    
    name_map = {}
    
    resources.keys.each do |name|
      name_map[name] = true
    end
    config[:resource_names] = name_map
    
    resources.each do |name, resource|
      unless prefix.empty?
        name = "#{prefix}_#{name}"
      end
      results[name] = resource
    end
    return results
  end
  protected :translate
end
end
end
end

