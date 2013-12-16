
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
end

#-------------------------------------------------------------------------------
# Top level properties 

lib_dir      = File.dirname(__FILE__)
core_dir     = File.join(lib_dir, 'coral_core')
event_dir    = File.join(core_dir, 'event')
template_dir = File.join(core_dir, 'template')
util_dir     = File.join(core_dir, 'util')
 
#-------------------------------------------------------------------------------
# Coral requirements

git_location = coral_locate('git')
 
#-------------------------------------------------------------------------------

$:.unshift(lib_dir) unless
  $:.include?(lib_dir) || $:.include?(File.expand_path(lib_dir))

#---
  
require 'rubygems'
require 'log4r'
require 'deep_merge'
require 'json'

if git_location
  require 'grit'
end

#---

# Include pre core utilities (no internal dependencies)
[ :data, :disk, :cli, :process ].each do |name| 
  require File.join(util_dir, name.to_s + ".rb") 
end

if git_location
  require File.join(util_dir, 'git.rb')
end

# Include core
[ :config, :interface, :core, :resource, :template ].each do |name| 
  require File.join(core_dir, name.to_s + ".rb") 
end

# Include post core utilities 
# ( normally inherit from core and have no reverse dependencies with 
#   core classes )
#
[ :shell ].each do |name| 
  require File.join(util_dir, name.to_s + ".rb") 
end

# Include data model
[ :event, :command ].each do |name| 
  require File.join(core_dir, name.to_s + ".rb") 
end

if git_location
  [ :repository, :memory ].each do |name| 
    require File.join(core_dir, name.to_s + ".rb") 
  end  
end

# Include specialized events
Dir.glob(File.join(event_dir, '*.rb')).each do |file|
  require file
end

# Include bundled templates
Dir.glob(File.join(template_dir, '*.rb')).each do |file|
  require file
end

#*******************************************************************************
# Coral Core Library
#
# This provides core data elements and utilities used in the Coral gems.
#
# Author::    Adrian Webb (mailto:adrian.webb@coraltech.net)
# License::   GPLv3
module Coral
  
  VERSION    = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION'))
  CORAL_FILE = 'coral.json'
  
  #---
  
  @@ui = Coral::Core.ui
  
  #---
  
  def self.ui
    return @@ui
  end
  
  #-----------------------------------------------------------------------------
  # Initialization
  
  def self.load(base_path)
    if File.exists?(base_path)
      Dir.glob(File.join(base_path, '*.rb')).each do |file|
        require file
      end
      Dir.glob(File.join(base_path, 'event', '*.rb')).each do |file|
        require file
      end
      Dir.glob(File.join(base_path, 'template', '*.rb')).each do |file|
        require file
      end  
    end  
  end
  
  #---
  
  @@initialized = false
  
  def self.initialize
    unless @@initialized
      Config.set_property('time', Time.now.to_i)
      
      # Include Coral extensions
      Puppet::Node::Environment.new.modules.each do |mod|
        load(File.join(mod.path, 'lib', 'coral'))
      end      
            
      @@initialized = true
    end    
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
end

#-------------------------------------------------------------------------------
# Data type alterations

class Hash
  def search(search_key, options = {})
    config = Coral::Config.ensure(options)
    value  = nil
    
    recurse       = config.get(:recurse, false)
    recurse_level = config.get(:recurse_level, -1)
        
    self.each do |key, data|
      if key == search_key
        value = data
        
      elsif data.is_a?(Hash) && 
        recurse && (recurse_level == -1 || recurse_level > 0)
        
        recurse_level -= 1 unless recurse_level == -1
        value = value.search(search_key, 
          Coral::Config.new(config).set(:recurse_level, recurse_level)
        )
      end
      break unless value.nil?
    end
    return value
  end
end
