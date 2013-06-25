
module Coral
module Provisioner
module Puppet
class ResourceGroup < Core
   
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(provisioner, type_info, defaults = {})
    @provisioner = provisioner
    @info        = type_info
    
    @defaults    = symbol_map(hash(defaults))
    @resources   = {}
  end
     
  #-----------------------------------------------------------------------------
  # Checks

      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  attr_reader :provisioner, :info, :defaults, :resources
  
  #---
  
  def clear
    @resources = {}
    return self
  end
  
  #---
  
  def add(resources, options = {})
    config    = Config.ensure(options)
    resources = normalize(resources, config)
    
    unless Util::Data.empty?(resources)
      resources.each do |title, resource|
        case info[:type]
        when :type, :define
          provisioner.add_resource(info, title, resource.properties)
        when :class
          provisioner.add_class(info, title, resource.properties)
        end
        @resources[title] = resource
      end
    end
    return self
  end

  #-----------------------------------------------------------------------------
  # Resource operations
  
  def normalize(type_name, resources, options = {})
    clear_composite_resources
    
    config    = Config.ensure(options)
    resources = Util::Data.value(resources)
    
    #dbg(resources, 'normalize -> init')
    
    unless Util::Data.empty?(resources)
      resources.keys.each do |name|
        #dbg(name, 'normalize -> name')
        if ! resources[name] || resources[name].empty? || ! resources[name].is_a?(Hash)        
          resources.delete(name)
        else
          normalize = true
          
          namevar = provisioner.namevar(type_name, name)
          if resources[name].has_key?(namevar)
            value = resources[name][namevar]
            if Util::Data.empty?(value)
              #dbg(value, "delete #{name}")
              resources.delete(name)
              normalize = false
              
            elsif value.is_a?(Array)
              value.each do |item|
                item_name = "#{name}_#{item}".gsub(/\-/, '_')
                
                new_resource = resources[name].clone
                new_resource[namevar] = item
                
                resources[item_name] = render(new_resource, config)
                add_composite_resource(name, item_name)
              end
              resources.delete(name)
              normalize = false
            end  
          end
          
          #dbg(resources, 'normalize -> resources')
          
          if normalize
            resource = Resource.new(provisioner, info, name, resources[name])
            resource.set_defaults(defaults, config.import({ :groups => composite_resources }))
            
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
        
    #dbg(resources, 'resources -> translate')
    
    prefix = config.get(:resource_prefix, '')
    
    name_map = {}
    resources.keys.each do |name|
      name_map[name] = true
    end
    config[:resource_names] = name_map
    
    resources.each do |name, resource|
      #dbg(name, 'name')
      #dbg(resource, 'resource')
      
      unless prefix.empty?
        name = "#{prefix}_#{name}"
      end
      results[name] = resource
    end
    return results
  end
  protected :translate
  
  #-----------------------------------------------------------------------------
  # Resource group tables

  @composite_resources = {}
  
  #---
  
  def composite_resources
    return @composite_resources
  end
  
  #---
  
  def clear_composite_resources
    @composite_resources = {}
  end
  
  #---
  
  def add_composite_resource(name, resource_names)
    @composite_resources[name] = [] unless @composite_resources[name].is_a?(Array)
    
    unless resource_names.is_a?(Array)
      resource_names = [ resource_names ]
    end
    
    resource_names.each do |r_name|
      unless @composite_resources[name].include?(r_name)
        @composite_resources[name] << r_name
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities

end
end
end
end
