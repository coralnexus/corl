
module Coral
module Plugin
 
  #-----------------------------------------------------------------------------
  # Plugin instances
  
  @@load_info = {}
  @@types     = {}
  @@plugins   = {}
  
  #---

  @@gems = {}
  @@core = nil
  
  #---
  
  def self.create_instance(type, provider, options = {})
    type     = type.to_sym
    provider = provider.to_sym
    
    dbg(type, 'type')
    dbg(provider, 'provider')
    dbg(options, 'options')
    dbg(@@types, 'types')
    dbg(@@core)
    dbg(@@gems, 'gems')
    dbg(@@load_info, 'loaded info')
    
    return nil unless @@types.has_key?(type)
    
    options  = translate_type(type, options)
    provider = options.delete(:provider).to_sym if options.has_key?(:provider)    
    info     = @@load_info[type][provider] if Util::Data.exists?(@@load_info, [ type, provider ])
    
    dbg(options, 'modified options')
    dbg(provider, 'modified provider')
    dbg(info, 'info')
        
    if info
      options       = translate(type, provider, options)      
      instance_name = "#{provider}_" + Coral.sha1(options)
      
      @@plugins[type] = {} unless @@plugins.has_key?(type)
      
      unless instance_name && @@plugins[type].has_key?(instance_name)
        plugin = Coral.class_const([ :coral, type, provider ]).new(type, provider, options)
        
        info[:instance_name] = instance_name
        plugin.set_meta(info) 
        
        @@plugins[type][instance_name] = plugin 
      end
           
      return @@plugins[type][instance_name]
    end      
    return nil
  end
  
  #---
  
  def self.get_instance(type, name)
    if @@plugins.has_key?(type)
      @@plugins[type].each do |instance_name, plugin|
        return plugin if plugin.name == name
      end
    end
    return nil  
  end
  
  #---
  
  def self.remove_instance(plugin)
    if plugin && plugin.is_a?(Plugin::Base) && @@plugins.has_key?(plugin.plugin_type)
      @@plugins[plugin.plugin_type].delete(plugin.plugin_instance_name)
    end
  end
 
  #-----------------------------------------------------------------------------
  # Plugins and resources
  
  def self.core
    return @@core
  end
  
  #---
  
  def self.register_gem(spec)
    plugin_path = File.join(spec.full_gem_path, 'lib', 'coral')
    if File.directory?(plugin_path)
      @@gems[spec.name] = {
        :lib_dir => plugin_path,
        :spec    => spec
      }
      if spec.name == 'coral_core'
        @@core = spec
      else
        register(plugin_path) # Autoload plugins and related files  
      end      
    end  
  end
  
  #---
  
  def self.gems(reset = false)
    if reset || Util::Data.empty?(@@gems)
      if defined?(Gem) 
        if ! defined?(Bundler) && Gem::Specification.respond_to?(:latest_specs)
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
  
  #-----------------------------------------------------------------------------
  
  def self.define_type(type_info)
    if type_info.is_a?(Hash)
      type_info.each do |type, default_provider|
        @@types[type.to_sym] = default_provider
      end
    end
  end
  
  #---
  
  def self.types
    return @@types.keys
  end
  
  #---
  
  def self.type_default(type)
    return @@types[type.to_sym]
  end
  
  #---
  
  def self.plugins(type = nil)
    results = {}
    
    if type
      results[type] = @@plugins[type] if @@plugins.has_key?(type)
    else
      results = @@plugins
    end    
    return results
  end
 
  #---
  
  def self.add_build_info(type, file)
    type = type.to_sym
    
    @@load_info[type] = {} unless @@load_info.has_key?(type)
    
    components = file.split(File::SEPARATOR)
    provider   = components.pop.sub(/\.rb/, '').to_sym
    directory  = components.join(File::SEPARATOR) 
    
    puts 'Loading ' + type.to_s + ' plugin: ' + provider.to_s
        
    unless @@load_info[type].has_key?(provider)
      data = {
        :type      => type,
        :provider  => provider,        
        :directory => directory,
        :file      => file
      }
      @@load_info[type][provider] = data
    end
  end
 
  #-----------------------------------------------------------------------------
  # Plugin autoloading
  
  def self.register_type(base_path, plugin_type)
    base_directory = File.join(base_path, plugin_type.to_s)
    
    if File.directory?(base_directory)
      Dir.glob(File.join(base_directory, '*.rb')).each do |file|
        add_build_info(plugin_type, file)
      end
    end
  end
  
  #---
 
  def self.register(base_path)
    if File.directory?(base_path)
      Dir.glob(File.join(base_path, '*.rb')).each do |file|
        require file
      end
      
      Dir.entries(base_path).each do |path|
        unless path.match(/^\.\.?$/)
          register_type(base_path, path)          
        end
      end
    end  
  end
  
  #---
  
  def self.autoload
    @@load_info.keys.each do |type|
      @@load_info[type].each do |provider, plugin|
        coral_require(plugin[:directory], provider)
      end      
    end 
  end
    
  #---
  
  @@initialized = false
  
  #---
  
  def self.initialize
    unless @@initialized
      # Register core plugins
      register(File.join(File.dirname(__FILE__), '..', 'coral'))      
      
      # Register external Gem defined plugins
      gems(true)
      
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
  # Utilities
  
  def self.translate_type(type, info, method = :translate)
    klass = Coral.class_const([ :coral, :plugin, type ])          
    info  = klass.send(method, info) if klass.respond_to?(method)
    return info  
  end
  
  #---
  
  def self.translate(type, provider, info, method = :translate)
    klass = Coral.class_const([ :coral, type, provider ])          
    info  = klass.send(method, info) if klass.respond_to?(method)
    return info  
  end
  
  #-----------------------------------------------------------------------------
  # Core plugin types
  
  define_type :network => :default, 
              :node    => :default,
              :machine => :fog
              
  #-----------------------------------------------------------------------------
  # Base plugin
  
class Base < Core
  # All Plugin classes should directly or indirectly extend Base
  
  def intialize(type, provider, options)
    name = Util::Data.ensure_value(options.delete(:name), provider)
    
    super(options)
    
    self.name = name
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
  
  def name
    return get(:name)
  end
  
  #---
  
  def name=name
    set(:name, string(name))
  end
  
  #---
  
  def meta
    return @meta
  end
  
  #---
  
  def set_meta(meta)
    @meta = Config.ensure(meta)
  end
  protected :set_meta
 
  #---
  
  def plugin_type
    return meta.get(:type)
  end
  
  #---
  
  def plugin_provider
    return meta.get(:provider)
  end
  
  #---
  
  def plugin_directory
    return meta.get(:directory)
  end
  
  #---
  
  def plugin_file
    return meta.get(:file)
  end
  
  #---
  
  def plugin_instance_name
    return meta.get(:instance_name)
  end
  
  #---
  
  def plugin_parent=parent
    meta.set(:parent, parent) if parent.is_a?(Coral::Plugin::Base)
  end
  
  #---
  
  def plugin_parent
    return meta.get(:parent)
  end

  #-----------------------------------------------------------------------------
  # Plugin operations
    
  def normalize
  end

  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info(type, data)  
    plugins = []
    
    if data.is_a?(Hash)
      data = [ data ]
    end
    
    if data.is_a?(Array)
      data.each do |info|
        unless Util::Data.empty?(info)
          info = translate(info)
          
          if Util::Data.empty?(info[:provider])
            info[:provider] = Plugin.type_default(type)
          end
          
          plugins << info
        end
      end
    end
    return plugins
  end
  
  #---

  def self.translate(data)
    return ( data.is_a?(Hash) ? symbol_map(data) : {} )
  end
end
end
end
