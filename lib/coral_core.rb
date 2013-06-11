
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
require 'puppet'
require 'hiera'

require 'i18n'

#---

begin
  require 'log4r'
    
rescue LoadError
  log4r_lib = File.join(dependencies, 'log4r', 'lib')
  
  $:.push(log4r_lib)
  require 'log4r'  
end

#---

begin
  require 'deep_merge'
    
rescue LoadError
  deep_merge_lib = File.join(dependencies, 'deep_merge', 'lib')
  
  $:.push(deep_merge_lib)
  require 'deep_merge'
end

#---

begin
  require 'multi_json'
    
rescue LoadError
  json_lib = File.join(dependencies, 'json', 'lib')
  $:.push(json_lib)
  require File.join(json_lib, 'json', 'pure.rb')  
  
  json_lib = File.join(dependencies, 'multi_json', 'lib')  
  $:.push(json_lib)
  require 'multi_json'
end

#---

begin
  require 'posix-spawn'
    
rescue LoadError
  posix_spawn_lib = File.join(dependencies, 'posix-spawn', 'lib')
  
  $:.push(posix_spawn_lib)
  require 'posix-spawn'
end

#---

begin
  require 'mime-types'
    
rescue LoadError
  mime_types_lib = File.join(dependencies, 'mime-types', 'lib')
  
  $:.push(mime_types_lib)
  require 'mime-types'
end

#---

begin
  require 'diff-lcs'
    
rescue LoadError
  diff_lcs_lib = File.join(dependencies, 'diff-lcs', 'lib')
  
  $:.push(diff_lcs_lib)
  require 'diff-lcs'
end

#---

if git_location
  begin
    require 'grit'
    
  rescue LoadError
    git_lib = File.join(dependencies, 'grit', 'lib')
  
    $:.push(git_lib)
    require 'grit'
  end
end

#---

# Include pre core utilities (no internal dependencies)
[ :data, :disk, :process ].each do |name| 
  require File.join('coral_core', 'util', name.to_s + '.rb') 
end

# Include core
[ :config, :interface, :core, :resource, :template ].each do |name| 
  require File.join('coral_core', name.to_s + '.rb') 
end

# Include post core utilities 
# ( normally inherit from core and have no reverse dependencies with 
#   core classes )
#
[ :option, :shell ].each do |name| 
  require File.join('coral_core', 'util', name.to_s + '.rb') 
end

# Include data model
[ :event, :command ].each do |name| 
  require File.join('coral_core', name.to_s + '.rb') 
end

if git_location
  [ :repository, :configuration ].each do |name| 
    require File.join('coral_core', name.to_s + '.rb') 
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

#---

require 'hiera_backend.rb'

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
