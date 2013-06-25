
module Coral
module Provisioner
module Puppet
class Resource < Core
   
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(provisioner, info, title, properties = {})
    @provisioner = provisioner
    @info        = info
    
    @title       = title
    @properties  = symbol_map(hash(properties))
    @ready       = false  
  end
     
  #-----------------------------------------------------------------------------
  # Checks

      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  attr_reader :provisioner, :info, :title, :properties, :ready
  
  #---
  
  def [](key)
    return properties[key]
  end
  
  #---
  
  def set_defaults(defaults, options = {})
    @properties = Util::Data.merge([ symbol_map(hash(defaults)), properties ])
    @ready      = false
    process(options)
    return self 
  end

  #---
  
  def set_overrides(overrides, options = {})
    @properties = Util::Data.merge([ properties, symbol_map(hash(overrides)) ])
    @ready      = false
    process(options)
    return self  
  end
  
  #---
  
  def project=project
    @project = project
  end
      
  #-----------------------------------------------------------------------------
  # Resource operations
  
  def ensure_ready(options = {})
    unless ready
      process(options)
    end
  end
  
  #---
  
  def process(options = {})
    tag(options[:tag])
    render(options)
    translate(options)
    @ready = true # Ready for resource creation
    return self
  end
  
  #---
  
  def tag(tag, append = true)
    unless tag.empty?
      tag = tag.to_s
      
      if ! properties.has_key?(:tag)
        properties[:tag] = tag
      else
        resource_tags = properties[:tag]
        
        case resource_tags
        when Array
          properties[:tag] << tag
          
        when String
          resource_tags    = resource_tags.split(/\s*,\s*/).push(tag)
          properties[:tag] = resource_tags
        end
      end
    end
    return self
  end
  
  #---

  def self.render(options = {})
    resource = string_map(@properties)
    config   = Config.ensure(options)
    
    resource.keys.each do |name|
      if match = name.to_s.match(/^(.+)_template$/)
        target = match.captures[0]
        
        #dbg(name, 'name')
        #dbg(target, 'target')
        
        config.set(:normalize_template, config.get("normalize_#{target}", true))
        config.set(:interpolate_template, config.get("interpolate_#{target}", true))
        
        properties[target] = Template.render(properties[name], properties[target], config)
        properties.delete(name)         
      end
    end    
    return self
  end
  
  #---
  
  def translate(options = {})
    config = Config.ensure(options)
    
    properties[:before]    = translate_resource_refs(properties[:before], config) if properties.has_key?(:before)
    properties[:notify]    = translate_resource_refs(properties[:notify], config) if properties.has_key?(:notify)
    properties[:require]   = translate_resource_refs(properties[:require], config) if properties.has_key?(:require)       
    properties[:subscribe] = translate_resource_refs(properties[:subscribe], config) if properties.has_key?(:subscribe)
    
    #dbg(properties, 'translate exit')    
    return self
  end

  #-----------------------------------------------------------------------------
  # Utilities
  
  def translate_resource_refs(resource_refs, options = {})
    return :undef if Util::Data.undef?(resource_refs)
    
    config         = Config.ensure(options)
    resource_names = config.get(:resource_names, {})
    title_prefix   = config.get(:title_prefix, '')
    
    title_pattern  = config.get(:title_pattern, '^\s*([^\[\]]+)\s*$')
    title_group    = config.get(:title_var_group, 1)
    title_flags    = config.get(:title_flags, '')
    title_regexp   = Regexp.new(title_pattern, title_flags.split(''))
    
    groups         = config.get(:groups, {})
    
    allow_single   = config.get(:allow_single_return, true)    
    
    type_name      = info[:name].sub(/^\@?\@/, '')
    values         = []
        
    case resource_refs
    when String
      if resource_refs.empty?
        return :undef 
      else
        resource_refs = resource_refs.split(/\s*,\s*/)
      end
        
    when Puppet::Resource
      resource_refs = [ resource_refs ]  
    end
    
    resource_refs.collect! do |value|
      if value.is_a?(Puppet::Resource) || ! value.match(title_regexp)
        value
          
      elsif resource_names.has_key?(value)
        if ! title_prefix.empty?
          "#{title_prefix}_#{value}"
        else
          value
        end
        
      elsif groups.has_key?(value) && ! groups[value].empty?
        results = []
        groups[value].each do |resource_name|
          unless title_prefix.empty?
            resource_name = "#{title_prefix}_#{resource_name}"
          end
          results << resource_name        
        end
        results
        
      else
        nil
      end           
    end
    
    resource_refs.flatten.each do |ref|
      #dbg(ref, 'reference -> init')
      unless ref.nil?        
        unless ref.is_a?(Puppet::Resource)
          ref = ref.match(title_regexp) ? Puppet::Resource.new(type_name, ref) : Puppet::Resource.new(ref)
        end
        #dbg(ref, 'reference -> final')       
        values << ref unless ref.nil?
      end
    end
    
    return values[0] if allow_single && values.length == 1
    return values
  end
  protected :translate_resource_refs
end
end
end
end
