
module Coral
module Provisioner
module Puppet
class Resource < Core
  
  extend Mixin::SubConfig
   
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(provisioner, info, title, properties = {})
    super({
      :title       => string(title),
      :info        => hash(info),
      :provisioner => provisioner,
      :ready       => false
    })
    import(properties) 
  end
     
  #-----------------------------------------------------------------------------
  # Checks

      
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def provisioner(default = nil)
    return _get(:provisioner, default)
  end
  
  #---
  
  def provisioner=provisioner
    _set(:provisioner, provisioner)
  end
  
  #---
  
  def info(default = {})
    return hash(_get(:info, default))
  end
  
  #---
  
  def info=info
    _set(:info, hash(info))
  end
  
  #---
  
  def title(default = '')
    return string(_get(:title, default))
  end
  
  #---
  
  def title=info
    _set(:title, string(info))
  end
  
  #---
  
  def ready(default = false)
    return test(_get(:ready, default))
  end
 
  #---
  
  def defaults(defaults, options = {})
    super(defaults, options)
    
    _set(:ready, false)
    process(options)
    return self 
  end

  #---
  
  def import(properties, options = {})
    super(defaults, options)
    
    _set(:ready, false)
    process(options)
    return self  
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
    config = Config.ensure(options)
    
    tag(config[:tag])
    
    render(config)
    translate(config)
    
    _set(:ready, true) # Ready for resource creation
    return self
  end
  
  #---
  
  def tag(tag, append = true)
    unless Util::Data.empty?(tag)
      tag           = tag.to_s.split(/\s*,\s*/)
      resource_tags = get(:tag)
      
      if ! resource_tags || ! append
        set(:tag, tag)
      else
        resource_tags << tag
        set(:tag, resource_tags)
      end
    end
    return self
  end
  
  #---

  def render(options = {})
    resource = string_map(export)
    config   = Config.ensure(options)
    
    resource.keys.each do |name|
      if match = name.to_s.match(/^(.+)_template$/)
        target = match.captures[0]
        
        config.set(:normalize_template, config.get("normalize_#{target}", true))
        config.set(:interpolate_template, config.get("interpolate_#{target}", true))
        
        set(target, Coral.template(properties[name], config).render(properties[target]))
        delete(name)         
      end
    end    
    return self
  end
  
  #---
  
  def translate(options = {})
    config = Config.ensure(options)
    
    set(:before, translate_resource_refs(get(:before), config)) if get(:before)
    set(:notify, translate_resource_refs(get(:notify), config)) if get(:notify)
    set(:require, translate_resource_refs(get(:require), config)) if get(:require)       
    set(:subscribe, translate_resource_refs(get(:subscribe), config)) if get(:subscribe)
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
      unless ref.nil?        
        unless ref.is_a?(Puppet::Resource)
          ref = ref.match(title_regexp) ? Puppet::Resource.new(type_name, ref) : Puppet::Resource.new(ref)
        end
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
