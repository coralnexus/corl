
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

#---

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
  
  def self.context(provider, options = {})
    return Plugin.instance(:context, provider, options)
  end
  
  #---
  
  def self.command(options, provider = :shell)
    return Plugin.instance(:command, provider, options)
  end
  
  #---
  
  def self.event(options, provider = :regex)
    return Plugin.instance(:event, provider, options)
  end
  
  #---
  
  def self.events(options, build_hash = false, keep_array = false)
    group  = ( build_hash ? {} : [] )    
    events = Plugin::Event.build_info(options)
    
    index = 1
    events.each do |info|
      type = info[:type]
      
      if type && ! type.empty?
        event = event(info, type)
                
        if event
          if build_hash
            group[index] = event
          else
            group << event
          end
        end
      end
      index += 1
    end
    if ! build_hash && events.length == 1 && ! keep_array
      return group.shift
    end
    return group  
  end
  
  #---
  
  def self.template(provider, options = {})
    return Plugin.instance(:template, provider, options)
  end
  
  #---
  
  def self.provisioner(provider = :puppet, options = {})
    return Plugin.instance(:provisioner, provider, options)
  end
  
  #---
  
  def self.project(project = {})
    return nil unless project
    
    unless project.is_a?(Hash)
      project = {
        :url      => project,
        :revision => nil
      }
    end   
    
    project  = Util::Data.symbol_map(project)
    provider = :git
    
    if match = project[:url].match(/^([a-zA-Z0-9_]+)::(.+)$/)
      type, url     = match.captures
      provider      = type.strip
      project[:url] = url
    end
    
    return Plugin.instance(:project, provider, project)
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

Coral.initialize
