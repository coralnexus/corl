
#*******************************************************************************
# Coral Core Library
#
# This provides core data elements and utilities used in the Coral gems.
#
# Author::    Adrian Webb (mailto:adrian.webb@coraltech.net)
# License::   GPLv3

#-------------------------------------------------------------------------------
# Global namespace

module Kernel
   
  def dbg(data, label = '')
    # Invocations of this function should NOT be committed to the project
    require 'pp'
    
    puts '>>----------------------'
    unless label.empty?
      puts label
      puts '---'
    end
    pp data
    puts '<<'
  end
  
  #---  
    
  def coral_locate(command)
    command = command.to_s
    exts    = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{command}#{ext}")
        return exe if File.executable?(exe)
      end
    end
    return nil
  end
    
  #---
  
  def coral_require(base_dir, name)
    name = name.to_s
    
    require File.join(base_dir, "#{name}.rb")  
    directory = File.join(base_dir, name)
      
    if File.directory?(directory)
      Dir.glob(File.join(directory, '**', '*.rb')).each do |sub_file|
        require sub_file
      end
    end  
  end
end

#-------------------------------------------------------------------------------
# Top level properties 

lib_dir      = File.dirname(__FILE__)
core_dir     = File.join(lib_dir, 'coral_core')
mixin_dir    = File.join(core_dir, 'mixin')
macro_dir    = File.join(mixin_dir, 'macro')
event_dir    = File.join(core_dir, 'event')
template_dir = File.join(core_dir, 'template')
util_dir     = File.join(core_dir, 'util')
mod_dir      = File.join(core_dir, 'mod')
 
#-------------------------------------------------------------------------------
# Coral requirements

git_location = coral_locate('git')

$:.unshift(lib_dir) unless $:.include?(lib_dir) || $:.include?(File.expand_path(lib_dir))

#---
  
require 'rubygems'

require 'i18n'
require 'log4r'
require 'deep_merge'
require 'yaml'
require 'multi_json'
require 'digest/sha1'

require 'puppet'
require 'fog'

#---

# TODO: Make this dynamically settable

#I18n.load_path << File.expand_path(File.join('..', 'locales', 'en.yml'), lib_dir)

#---

if git_location
  require 'grit'
  coral_require(util_dir, :git)
end

#---

# Object modifications (100% pure monkey patches)
Dir.glob(File.join(mod_dir, '*.rb')).each do |file|
  require file
end

#---

# Mixins for classes
Dir.glob(File.join(mixin_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(macro_dir, '*.rb')).each do |file|
  require file
end

#---

coral_require(util_dir, :data)
coral_require(core_dir, :config)
coral_require(util_dir, :interface) 
coral_require(core_dir, :core) 

# Include core utilities
[ :cli, :disk, :process, :shell ].each do |name| 
  coral_require(util_dir, name)
end

# Include core systems
[ :event, :template, :repository, :resource, :plugin_base, :plugin ].each do |name|
  coral_require(core_dir, name)
end

#*******************************************************************************
# Coral Core Library
#
# This provides core data elements and utilities used in the Coral gems.
#
# Author::    Adrian Webb (mailto:adrian.webb@coraltech.net)
# License::   GPLv3
module Coral
  
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION'))
  
  #---
  
  @@config_file = 'coral.json'
  
  #-----------------------------------------------------------------------------
  
  def self.ui
    return Core.ui
  end
  
  #---
  
  def self.logger
    return Core.logger
  end
  
  #-----------------------------------------------------------------------------
  
  def self.config_file=file_name
    @@config_file = file_name
  end
  
  #---
  
  def self.config_file
    return @@config_file
  end
  
  #-----------------------------------------------------------------------------
  # Initialization
  
  @@initialized = false
  
  def self.initialize
    unless @@initialized
      Config.set_property('time', Time.now.to_i)
      
      begin
        # Include Coral plugins
        Puppet::Node::Environment.new.modules.each do |mod|
          lib_path = File.join(mod.path, 'lib', 'coral')
          Plugin.register(lib_path)
        end
      rescue
      end
      
      Plugin.initialize
            
      @@initialized = true
    end    
  end
  
  #---
  
  def self.initialized?
    return @@initialized
  end
    
  #-----------------------------------------------------------------------------
  # Plugins
  
  def self.plugin(type, provider, options = {})
    default_provider = Plugin.type_default(type)
    
    if options.is_a?(Hash) || options.is_a?(Coral::Config)
      config   = Config.ensure(options)
      provider = config.get(:provider, provider)
      name     = config.get(:name, ( provider ? provider : default_provider ))
      options  = config.export
    end
    provider          = default_provider unless provider # Sanity checking (see plugins)
    existing_instance = Plugin.get_instance(type, name) if name
    
    return existing_instance if existing_instance
    return Plugin.create_instance(type, provider, options)
  end
  
  #---
  
  def self.plugins(type, data, build_hash = false, keep_array = false)
    group = ( build_hash ? {} : [] )
    klass = class_const([ :coral, :plugin, type ])    
    data  = klass.build_info(type, data) if klass.respond_to?(:build_info)
    
    data.each do |options|
      if plugin = plugin(type, options[:provider], options)
        if build_hash
          group[plugin.name] = plugin
        else
          group << plugin
        end
      end
    end
    return group.shift if ! build_hash && group.length == 1 && ! keep_array
    return group  
  end
  
  #---
  
  def self.get_plugin(type, name)
    return Plugin.get_instance(type, name)
  end
  
  #---
  
  def self.remove_plugin(plugin)
    return Plugin.remove_instance(plugin)
  end
  
  #-----------------------------------------------------------------------------
  # Core plugin type facade
   
  def self.network(name, options = {}, provider = nil)
    plugin      = plugin(:network, provider, options)
    plugin.name = name
    return plugin
  end
  
  #---
  
  def self.networks(data, build_hash = false, keep_array = false)
    return plugins(:network, data, build_hash, keep_array)
  end
   
  #---
  
  def self.node(name, options = {}, provider = nil)
    plugin      = plugin(:node, provider, options)
    plugin.name = name
    return plugin
  end
  
  #---
  
  def self.nodes(data, build_hash = false, keep_array = false)
    return plugins(:node, data, build_hash, keep_array)
  end
   
  #---
  
  def self.machine(options = {}, provider = nil)
    plugin = plugin(:machine, provider, options)
    return plugin
  end
  
  #---
  
  def self.machines(data, build_hash = false, keep_array = false)
    return plugins(:machine, data, build_hash, keep_array)
  end
  
  #---
  
  def self.command(options, provider = nil)
    return plugin(:command, provider, options)
  end
  
  #---
  
  def self.commands(data, build_hash = false, keep_array = false)
    return plugins(:command, data, build_hash, keep_array)
  end
     
  #-----------------------------------------------------------------------------
  # External execution
   
  def self.run
    begin
      initialize
      yield
      
    rescue Exception => error
      ui.warn(error.inspect)
      ui.warn(Util::Data.to_yaml(error.backtrace))
      raise
    end
  end
    
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.class_name(name, separator = '::', want_array = FALSE)
    components = []
    
    case name
    when String, Symbol
      components = name.to_s.split(separator)
    when Array
      components = name 
    end
    
    components.collect! do |value|
      value.to_s.strip.capitalize  
    end
    
    if want_array
      return components
    end    
    return components.join(separator)
  end
  
  #---
  
  def self.class_const(name, separator = '::')
    components = class_name(name, separator, TRUE)
    constant   = Object
    
    components.each do |component|
      constant = constant.const_defined?(component) ? 
                  constant.const_get(component) : 
                  constant.const_missing(component)
    end
    
    return constant
  end
  
  #---
  
  def self.sha1(data)
    return Digest::SHA1.hexdigest(Util::Data.to_json(data, false))
  end  
end

#-------------------------------------------------------------------------------
# Coral initialization

Coral.initialize
