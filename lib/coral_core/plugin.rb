
module Coral
module Plugin
  
  #-----------------------------------------------------------------------------
  # Plugin types
  
  define_type :command
  define_type :context
  define_type :event
  define_type :project
  define_type :provisioner
  define_type :template
  
  #-----------------------------------------------------------------------------
  # Plugin initialization
  
  @@load_info = {}
  @@types     = {}
  @@plugins   = {}
  
  #---

  @@gems = {}
  @@core = nil
  
  #---
  
  def self.instance(type, name, options = {})
    type = type.to_sym
    name = name.to_sym
    return nil unless @@types.has_key?(type)
    
    config = Config.ensure(options)    
    info   = @@load_info[type][name] if @@load_info[type].has_key?(name)
    
    if info
      group_name    = "#{type}_#{name}"
      instance_name = Coral.sha1(options)
      
      @@plugins[group_name] = {} unless @@plugins.has_key?(group_name)
      
      unless instance_name && @@plugins[group_name].has_key?(instance_name)
        plugin = Coral.class_const(class_name([ :coral, type, name ])).new(name, config)
        plugin.set_meta(info) 
        
        @@plugins[group_name][instance_name] = plugin 
      end
           
      return @@plugins[group_name][instance_name]
    end      
    return nil
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
  
  #-----------------------------------------------------------------------------
  
  def self.define_type(type)
    @@types[type_name] = true
  end
  
  #---
  
  def self.types
    return @@types.keys
  end
  
  #---
  
  def self.plugins(type = nil)
    results = {}
    
    if type
      type = type.to_sym    
      return results unless @@plugins.has_key?(type)
      results[type] = @@plugins[type].dup
    else
      results = @@plugins.dup 
    end    
    return results
  end
 
  #---
  
  def self.add_build_info(type, file)
    type = type.to_sym
    
    @@load_info[type] = {} unless @@load_info.has_key?(type)
    
    components = file.split(File::SEPARATOR)
    name       = components.pop.sub(/\.rb/, '')
    directory  = components.join(File::SEPARATOR) 
        
    unless @@load_info[type].has_key?(name)
      data = {
        :name      => name,
        :type      => type,
        :directory => directory,
        :file      => file
      }
      @@load_info[type][name] = data
    end
  end
  protected :add_build_info
 
  #-----------------------------------------------------------------------------
  # Plugin autoloading
 
  def self.register(base_path)
    if File.directory?(base_path)
      Dir.glob(File.join(base_path, '*.rb')).each do |file|
        require file
      end
      
      Dir.entries(base_path).each do |path|
        if File.directory?(path) && ! path.match(/^\.\.?$/)
          register_type(base_path, path)          
        end
      end
    end  
  end
  
  #---
  
  def self.register_type(base_path, plugin_type)
    base_directory = File.join(base_path, plugin_type.to_s)
    
    if File.directory?(base_directory)
      Dir.glob(File.join(base_directory, '*.rb')).each do |file|
        add_build_info(plugin_type, file)
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
      # Register Coral Gem plugins and other plugin defined plugins
      gems(true)
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
