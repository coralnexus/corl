
#*******************************************************************************
# Coral Core Library
#
# This provides core data elements and utilities used in the Coral gems.
#
# Author::    Adrian Webb (mailto:adrian.webb@coralnexus.com)
# License::   GPLv3

#-------------------------------------------------------------------------------
# Global namespace (might need these anywhere)

module Kernel
   
  def dbg(data, label = '')
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
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
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
git_location = coral_locate('git')
 
#-------------------------------------------------------------------------------
# Core requirements

$:.unshift(lib_dir) unless
  $:.include?(lib_dir) || $:.include?(File.expand_path(lib_dir))

#---
  
require 'rubygems'
require 'puppet'

#---

require 'i18n'
require 'log4r'
require 'deep_merge'
require 'multi_json'
require 'digest/sha1'

#---

if git_location
  require 'grit'
  coral_require(File.join(lib_dir, 'coral_core', 'util'), :git)
end

#---

# Include pre core utilities (no internal dependencies)
[ :data, :disk, :process ].each do |name| 
  coral_require(File.join(lib_dir, 'coral_core', 'util'), name)
end

# Include core
[ :config, :interface, :core, :provisioner ].each do |name| 
  coral_require(File.join(lib_dir, 'coral_core'), name) 
end

# Include post core utilities 
# ( normally inherit from core and have no reverse dependencies with 
#   core classes )
#
[ :option, :shell ].each do |name| 
  coral_require(File.join(lib_dir, 'coral_core', 'util'), name) 
end

# Include data model
[ :event, :command, :template, :project ].each do |name| 
  coral_require(File.join(lib_dir, 'coral_core'), name) 
end

if git_location
  [ :repository, :configuration, :builder ].each do |name| 
    coral_require(File.join(lib_dir, 'coral_core'), name) 
  end  
end

#---

# Extensions or Alterations to other classes
Dir.glob(File.join(lib_dir, 'coral_core', 'mod', '*.rb')).each do |file|
  require file
end

#*******************************************************************************
# Coral Core Library
#
# This provides core data elements and utilities used in the Coral gems.
#
# Author::    Adrian Webb (mailto:adrian.webb@coralnexus.com)
# License::   GPLv3
module Coral
  
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION'))
  
  #-----------------------------------------------------------------------------
  
  @@ui = Coral::Core.ui
  
  #---
  
  def self.ui
    return @@ui
  end
  
  #-----------------------------------------------------------------------------
  # Plugins and resources

  @@gems = {}
  
  #---
  
  def self.gems(reset = false)
    if reset || Util::Data.empty?(@@gems)
      if defined?(::Gem) && ! defined?(::Bundler) && Gem::Specification.respond_to?(:latest_specs)
        specs = Gem::Specification.latest_specs(true)
        specs.each do |spec|
          lib_path = File.join(spec.full_gem_path, 'lib', 'coral')
          if File.directory?(lib_path)
            load(lib_path) unless spec.name == 'coral_core'
            @@gems[spec.name] = {
              :lib_dir => lib_path,
              :spec    => spec
            }
          end
        end    
      end
    end    
    return @@gems
  end
  
  #---
  
  @@plugins = {}
  
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
    unless type
      return @@plugins
    end
    init_plugin_type(type)
    return @@plugins[type]
  end
  
  #---
  
  def self.get_class(plugin_type, name, default = nil)
    name   = default unless name
    plugin = plugins(plugin_type)[name] if name
    
    return nil unless plugin
    return Coral.class_const(plugin[:class])
  end
  
  #---
  
  def self.add_plugin(type, name, directory, file)
    type = type.to_sym
    init_plugin_type(type)
    
    plugin_data = {
      :name      => name,
      :type      => type,
      :class     => class_name([ :coral, type, name ]),
      :directory => directory,
      :file      => file
    }
    @@plugins[type][name] = plugin_data unless @@plugins[type].has_key?(name)
  end
  protected :add_plugin
  
  #---
  
  def self.load(base_path)
    if File.directory?(base_path)
      Dir.glob(File.join(base_path, '*.rb')).each do |file|
        require file
      end
      load_recursive(base_path, :event)
      load_recursive(base_path, :template)
      load_recursive(base_path, :project)
      load_recursive(base_path, :provisioner)      
    end  
  end
  protected :load
  
  #---
  
  def self.load_recursive(base_path, plugin_type)
    base_directory = File.join(base_path, plugin_type)
    
    if File.directory?(base_directory)
      Dir.glob(File.join(base_directory, '*.rb')).each do |file|
        components = file.split(FILE::SEPARATOR)
        name       = components.pop.sub(/\.rb/, '')
        directory  = components.join(FILE::SEPARATOR)
      
        coral_require(directory, name)
        add_plugin(plugin_type, name, directory, file)
      end
    end
  end
  protected :load_recursive
    
  #---
  
  @@initialized = false
  
  #---
  
  def self.initialize(lib_dir)
    unless @@initialized
      Config.set_property('time', Time.now.to_i)
      
      # Include core extensions
      load(File.join(lib_dir, 'coral_core'))
      
      # Include Ruby Coral Gem extensions
      gems(true)
            
      # Load provisioner extensions
      Provisioner.load
            
      @@initialized = true
    end    
  end
  
  #---
  
  def self.initialized?
    return @@initialized
  end
  
  #-----------------------------------------------------------------------------
  # Build process
  
  def self.builder(options = {})
    config = Config.ensure(options)
    
    project_path = config.get(:project_path, Dir.pwd)
    config_file  = config.get(:config_file, 'coral.json')
    build_path   = config.get(:build_path, 'build')
    
    return Builder.get("#{project_path}--#{config_file}--#{build_path}", { 
      :directory          => project_path,
      :config_file        => config_file,
      :build_path         => build_path,
      :provision_provider => config.get(:provisioner, :puppet)
    }, false)   
  end
  
  #---
  
  def self.build(options = {})
    builder = builder(options)   
    return builder.build
  end
  
  #-----------------------------------------------------------------------------
  # Provisioner
  
  def self.provisioner(provider = :puppet)
    return Provisioner.instance(:default, { :provider => provider })
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
  
  def self.class_name(name, separator = '::')
    components = []
    
    case name
    when String, Symbol
      components = name.to_s.split(separator)
    when Array
      components = name 
    end
    
    components.collect! do |value|
      name.to_s.strip.capitalize  
    end    
    return components.join(separator)
  end
  
  #---
  
  def self.class_const(klass)
    return Object::const_get(class_name(klass))
  end
  
  #---
  
  def self.sha1(data)
    return Digest::SHA1.hexdigest(Util::Data.to_json(data))
  end  
end

#-------------------------------------------------------------------------------
# Initialize the Coral configuration

Coral.initialize(lib_dir)
