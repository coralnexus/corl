
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
mixin_dir    = File.join(core_dir, 'mixins')
util_dir     = File.join(core_dir, 'util')
mod_dir      = File.join(core_dir, 'mod')

git_location = coral_locate(:git)
 
#-------------------------------------------------------------------------------
# Core requirements

$:.unshift(lib_dir) unless $:.include?(lib_dir) || $:.include?(File.expand_path(lib_dir))

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
  coral_require(util_dir, :git)
end

#---

# Object modifications
Dir.glob(File.join(mod_dir, '*.rb')).each do |file|
  require file
end

#---

# Mixins for classes
Dir.glob(File.join(mixin_dir, '*.rb')).each do |file|
  require file
end

#---

coral_require(util_dir, :data)
coral_require(core_dir, :config)
coral_require(core_dir, :interface) 
coral_require(core_dir, :core) 

# Include core utilities
[ :cli, :disk, :process, :shell ].each do |name| 
  coral_require(util_dir, name)
end

# Include core systems
[ :plugin, :builder ].each do |name| 
  coral_require(core_dir, name) 
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
  
  #---
  
  DEFAULT_BUILD_FILE = 'coral.json'
  
  #-----------------------------------------------------------------------------
  
  def self.ui
    return Core.ui
  end
  
  #---
  
  def self.logger
    return Core.logger
  end
  
  #-----------------------------------------------------------------------------
  # Initialization
  
  @@initialized = false
  
  #---
  
  def self.initialize
    unless @@initialized
      Config.set_property(:time, Time.now.to_i)
      
      # Include Coral plugins
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
  
  def self.plugin(type, name, options = {})
    if options.is_a?(Hash)
      config = Config.ensure(options)
      name   = config.get(:provider, name)
    end
    name = Plugin.type_default(type) unless name # Sanity checking (see plugins)
    return Plugin.instance(type, name, options)
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
  
  def self.context(options, provider = nil)
    return plugin(:context, provider, options)
  end
  
  #---
  
  def self.contexts(data, build_hash = false, keep_array = false)
    return plugins(:context, data, build_hash, keep_array)
  end
  
  #---
  
  def self.command(options, provider = nil)
    return plugin(:command, provider, options)
  end
  
  #---
  
  def self.commands(data, build_hash = false, keep_array = false)
    return plugins(:command, data, build_hash, keep_array)
  end
  
  #---
  
  def self.event(options, provider = nil)
    return plugin(:event, provider, options)
  end
  
  #---
  
  def self.events(data, build_hash = false, keep_array = false)
    return plugins(:event, data, build_hash, keep_array)
  end

  #---
  
  def self.template(provider, data)
    return plugin(:template, provider, data)
  end
  
  #---
  
  def self.templates(data, build_hash = false, keep_array = false)
    return plugins(:template, data, build_hash, keep_array)
  end
  
  #---
  
  def self.provisioner(provider = nil, options = {})
    return plugin(:provisioner, provider, options)
  end
  
  #---
  
  def self.provisioners(data, build_hash = false, keep_array = false)
    return plugins(:provisioner, data, build_hash, keep_array)
  end
  
  #---
  
  def self.project(options, provider = nil)
    return plugin(:project, provider, options)
  end
  
  #---
  
  def self.projects(data, build_hash = false, keep_array = false)
    return plugins(:project, data, build_hash, keep_array)
  end

  #-----------------------------------------------------------------------------
  # Build process
  
  def self.builder(options = {})
    config = Config.ensure(options)
    
    project_path = config.get(:project_path, Dir.pwd)
    config_file  = config.get(:config_file, Coral::DEFAULT_BUILD_FILE)
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
  # Execution
   
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
  
  #---
  
  def self.exec(hook, params = {}, context = :type, options = {})
    return Plugin.exec(hook, params, context, options)
  end
  
  #---
  
  def self.exec_type(type, hook, params = {})
    results = exec(hook, params, :type, { :filter_type => type })
    return results[type]
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
  
  def self.class_const(name, separator = '::')
    return Object::const_get(class_name(name, separator))
  end
  
  #---
  
  def self.sha1(data)
    return Digest::SHA1.hexdigest(Util::Data.to_json(data, false))
  end  
end

#-------------------------------------------------------------------------------
# Initialize the Coral configuration

Coral.initialize
