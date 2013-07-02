
module Coral
module Plugin
  
  #-----------------------------------------------------------------------------
  # Plugin initialization
  
  @@plugins   = {}
  @@instances = {}
  
  #---

  @@gems = {}
  @@core = nil
  
  #---
  
  def self.instance(type, name, options = {})
    init_plugin_type(type)
    
    name   = name.to_sym if name
    config = Config.ensure(options)
    
    plugin = @@plugins[type][name] if name && @@plugins[type].has_key?(name)
    
    if plugin
      group_name    = "#{type}_#{name}"
      instance_name = Coral.sha1(options)
      
      unless @@instances.has_key?(group_name) && @@instances[group_name]
        @@instances[group_name] = {}
      end      
      unless instance_name && @@instances[group_name].has_key?(instance_name)
        instance = get(type, name).new(name, config)
        instance.set_meta(plugin.meta)
        
        @@instances[group_name][instance_name] = instance 
      end      
      return @@instances[group_name][instance_name]
    end      
    return nil
  end
  
  #---
  
  def self.get(type, name, default = nil)
    return get_class(type, name, default)
  end
  
  #-----------------------------------------------------------------------------
  # Plugins and resources
  
  def self.core
    return @@core
  end
  
  #---
  
  def self.gems(reset = false)
    if reset || Util::Data.empty?(@@gems)
      if defined?(::Gem) 
        if ! defined?(::Bundler) && Gem::Specification.respond_to?(:latest_specs)
          Gem::Specification.latest_specs(true).each do |spec|
            register_gem(spec)
          end
        else
          Gem.loaded_specs.each do |name, spec|
            register_gem(spec)
          end     
        end
      end
    end    
    return @@gems
  end
  
  #---
  
  def self.register_gem(spec)
    lib_path = File.join(spec.full_gem_path, 'lib', 'coral')
    if File.directory?(lib_path)
      @@core = spec if spec.name == 'coral_core'
      @@gems[spec.name] = {
        :lib_dir => lib_path,
        :spec    => spec
      }
      register(lib_path) # Autoload plugins and related files
    end  
  end
  protected :register_gem
  
  #---
  
  def self.types
    return @@plugins.keys
  end
  
  #---
   
  def self.init_plugin_type(type)
    unless @@plugins.has_key?(type) && @@plugins[type]
      @@plugins[type] = {}
    end  
  end
  protected :init_plugin_type
  
  #---
  
  def self.plugins(type = nil)
    type = type.to_sym
    
    if type
      init_plugin_type(type)
      plugins = { type => @@plugins[type] }
    else
      plugins = @@plugins
    end
    
    results = {}
    plugins.each do |plugin_type, plugin_map|
      plugin_map.each do |name, info|
        results[plugin_type][name] = info[:plugin]
      end
    end
    
    return results unless type
    return results[type]
  end
  
  #---
  
  def self.get_class(plugin_type, name, default = nil)
    name   = default unless name
    plugin = @@plugins[plugin_type][name] if name
    
    return nil unless plugin
    return Coral.class_const(plugin[:class])
  end
  
  #---
  
  def self.add_plugin(type, name, directory, file)
    type = type.to_sym
    init_plugin_type(type)
    
    unless @@plugins[type].has_key?(name)
      plugin_data = {
        :name      => name,
        :type      => type,
        :class     => class_name([ :coral, type, name ]),
        :directory => directory,
        :file      => file
      }
      if plugin = instance(type, name)
        plugin.set_meta(plugin_data)   
        @@plugins[type][name] = plugin
      end
    end
  end
  protected :add_plugin
  
  #-----------------------------------------------------------------------------
  # Plugin autoloading
 
  def self.register(base_path)
    if File.directory?(base_path)
      Dir.glob(File.join(base_path, '*.rb')).each do |file|
        require file
      end
      types.each do |type|
        register_type(base_path, type)
      end   
    end  
  end
  
  #---
  
  def self.register_type(base_path, plugin_type)
    base_directory = File.join(base_path, plugin_type)
    
    if File.directory?(base_directory)
      Dir.glob(File.join(base_directory, '*.rb')).each do |file|
        components = file.split(FILE::SEPARATOR)
        name       = components.pop.sub(/\.rb/, '')
        directory  = components.join(FILE::SEPARATOR)      
        
        add_plugin(plugin_type, name, directory, file)
      end
    end
  end
  protected :register_type
  
  #---
  
  def self.autoload
    types.each do |type|
      plugins(type).each do |name, plugin|
        coral_require(plugin[:directory], plugin[:name])
      end      
    end 
  end
    
  #---
  
  @@initialized = false
  
  #---
  
  def self.initialize
    unless @@initialized
      # Register Ruby Coral Gem plugins
      gems(true)
            
      # Register plugin defined plugins
      exec(:register)
      
      # Autoload the registered plugins
      autoload
            
      @@initialized = true
    end    
  end
  
  #---
  
  def self.initialized?
    return @@initialized
  end
  
  #-----------------------------------------------------------------------------
  # Hook execution
 
  def self.exec(method, params = {}, context = :type, options = {})
    context = Coral.context(context, options)
    values  = {}
    
    return values unless context
    
    context.filter(plugins).each do |type, plugin_map|
      plugin_map.each do |name, plugin|
        values[type]       = {} unless values.has_key?(type)
        values[type][name] = context.translate(plugin.send(method, params))
      end
    end
    return values     
  end

  #-----------------------------------------------------------------------------
  # Base plugin
  
class Base < Core
  # All Plugin classes should directly or indirectly extend Base
  
  def intialize(name, options = {})
    super(options)
    
    init(:name, name)
    normalize
  end
  
  #---
  
  def initialized?(options = {})
    return true  
  end
  
  #---
  
  def method_missing(method, *args, &block)  
    return nil  
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def name(default = nil)
    return get(:name, default)
  end
  
  #---
  
  def meta
    return @meta
  end
  
  #---
  
  def set_meta(meta)
    @meta = Config.ensure(hash(meta))
  end
  protected :set_meta
  
  #---
  
  def plugin_name
    return meta.get(:name, :default)
  end
  
  #---
  
  def plugin_type
    return meta.get(:type)
  end
  
  #---
  
  def plugin_class
    return meta.get(:class)
  end
  
  #---
  
  def plugin_directory
    return meta.get(:directory)
  end
  
  #---
  
  def plugin_file
    return meta.get(:file)
  end

  #-----------------------------------------------------------------------------
  # Plugin operations
    
  def normalize
  end

  #---
  
  def register
  end
end
end
end
