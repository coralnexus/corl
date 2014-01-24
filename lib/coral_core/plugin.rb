
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
       
    return nil unless @@types.has_key?(type)
    
    options  = translate_type(type, options)
    provider = options.delete(:provider).to_sym if options.has_key?(:provider)    
    info     = @@load_info[type][provider] if Util::Data.exists?(@@load_info, [ type, provider ])
        
    if info
      options       = translate(type, provider, options)      
      instance_name = "#{provider}_" + Coral.sha1(options)
      
      @@plugins[type] = {} unless @@plugins.has_key?(type)
      
      unless instance_name && @@plugins[type].has_key?(instance_name)
        info[:instance_name] = instance_name
        options[:meta]       = info
        
        plugin = Coral.class_const([ :coral, type, provider ]).new(type, provider, options)
        
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
        return plugin if plugin.name.to_s == name.to_s
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
  
  def self.loaded_plugins(type = nil)
    if type
      return @@load_info[type] if @@load_info.has_key?(type)
      return {}
    end
    return @@load_info
  end
 
  #---
  
  def self.plugins(type = nil)
    if type
      return @@plugins[type] if @@plugins.has_key?(type)
      return {}
    end    
    return @@plugins
  end
 
  #---
  
  def self.add_build_info(type, file)
    type = type.to_sym
    
    @@load_info[type] = {} unless @@load_info.has_key?(type)
    
    components = file.split(File::SEPARATOR)
    provider   = components.pop.sub(/\.rb/, '').to_sym
    directory  = components.join(File::SEPARATOR) 
    
    Coral.logger.info('Loading coral ' + type.to_s + ' plugin: ' + provider.to_s)
        
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
        @@load_info[type][provider][:class] = Coral.class_const([ :coral, type, provider ])
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
      
      # Register any other dependent plugins
      yield if block_given?
      
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
end
end
