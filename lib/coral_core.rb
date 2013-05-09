
home = File.dirname(__FILE__)

$:.unshift(home) unless
  $:.include?(home) || $:.include?(File.expand_path(home))
  
#-------------------------------------------------------------------------------
  
require 'rubygems'
require 'hiera_backend.rb'

#---

# Include core
[ :interface, :core ].each do |name| 
  require File.join('coral_core', name.to_s + ".rb") 
end

# Include utilities
[ :git, :data, :disk, :shell ].each do |name| 
  require File.join('coral_core', 'util', name.to_s + ".rb") 
end

# Include Git overrides
Dir.glob(File.join(home, 'coral_core', 'util', 'git', '*.rb')).each do |file|
  require file
end

# Include data model
[ :event, :command, :repository, :memory ].each do |name| 
  require File.join('coral_core', name.to_s + ".rb") 
end

# Include specialized events
Dir.glob(File.join(home, 'coral_core', 'event', '*.rb')).each do |file|
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
end
