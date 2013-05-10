
#-------------------------------------------------------------------------------
# Global namespace

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
    
  def locate(command)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
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
# Properties and 

home         = File.dirname(__FILE__)
dependencies = File.join(home, 'dependency')

git_location = locate('git')
 
#-------------------------------------------------------------------------------

$:.unshift(home) unless
  $:.include?(home) || $:.include?(File.expand_path(home))

#---
  
require 'rubygems'
require 'hiera_backend.rb'

#---

begin
  require 'log4r'
    
rescue LoadError
  log4r_lib = File.join(dependencies, 'log4r', 'lib')
  
  $:.push(log4r_lib)
  require File.join(log4r_lib, 'log4r.rb')  
end

#---

begin
  require 'json'
    
rescue LoadError
  json_lib = File.join(dependencies, 'json', 'lib')
  
  $:.push(json_lib)
  require File.join(json_lib, 'json.rb')  
end

#---

if git_location
  begin
    require 'git'
    
  rescue LoadError
    git_lib = File.join(dependencies, 'git', 'lib')
  
    $:.push(git_lib)
    require File.join(git_lib, 'git.rb')  
  end
end

#---

# Include pre core utilities (no internal dependencies)
require File.join('coral_core', 'util', 'data.rb') 

if git_location
  require File.join('coral_core', 'util', 'git.rb') 

  # Include Git overrides
  Dir.glob(File.join(home, 'coral_core', 'util', 'git', '*.rb')).each do |file|
    require file
  end
end

# Include core
[ :config, :interface, :core, :resource, :template ].each do |name| 
  require File.join('coral_core', name.to_s + ".rb") 
end

# Include post core utilities 
# ( normally inherit from core and have no reverse dependencies with 
#   core classes )
#
[ :disk, :shell ].each do |name| 
  require File.join('coral_core', 'util', name.to_s + ".rb") 
end

# Include data model
[ :event, :command ].each do |name| 
  require File.join('coral_core', name.to_s + ".rb") 
end

if git_location
  [ :repository, :memory ].each do |name| 
    require File.join('coral_core', name.to_s + ".rb") 
  end  
end

# Include specialized events
Dir.glob(File.join(home, 'coral_core', 'event', '*.rb')).each do |file|
  require file
end

# Include bundled templates
Dir.glob(File.join(home, 'coral_core', 'template', '*.rb')).each do |file|
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
  
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION'))
  
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
      ui.warning(error.inspect)
      ui.warning(Util::Data.to_yaml(error.backtrace))
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
