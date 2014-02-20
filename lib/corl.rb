
#*******************************************************************************
# CORL Core Library
#
# This provides core data elements and utilities used in the CORL gems.
#
# Author::    Adrian Webb (mailto:adrian.webb@coralnexus.com)
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
    
  def corl_locate(command)
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
  
  def corl_require(base_dir, name)
    name = name.to_s
    top_level_file = File.join(base_dir, "#{name}.rb")
    
    require top_level_file if File.exists?(top_level_file) 
     
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

lib_dir          = File.dirname(__FILE__)
core_dir         = File.join(lib_dir, 'corl_core')
mixin_dir        = File.join(core_dir, 'mixin')
mixin_config_dir = File.join(mixin_dir, 'config')
mixin_action_dir = File.join(mixin_dir, 'action')
macro_dir        = File.join(mixin_dir, 'macro')
util_dir         = File.join(core_dir, 'util')
mod_dir          = File.join(core_dir, 'mod')
plugin_dir       = File.join(core_dir, 'plugin')
 
#-------------------------------------------------------------------------------
# CORL requirements

git_location = corl_locate('git')

$:.unshift(lib_dir) unless $:.include?(lib_dir) || $:.include?(File.expand_path(lib_dir))

#---
  
require 'rubygems'

require 'pp'
require 'i18n'
require 'log4r'
require 'log4r/configurator'
require 'base64'
require 'sshkey'
require 'deep_merge'
require 'hiera'
require 'facter'
require 'yaml'
require 'multi_json'
require 'digest/sha1'
require 'optparse'
require 'thread' # Eventually depreciated
require 'celluloid'
require 'celluloid/autostart'
require 'tmpdir'

#---

# TODO: Make this dynamically settable

I18n.enforce_available_locales = false
I18n.load_path << File.expand_path(File.join('..', 'locales', 'en.yml'), lib_dir)

#---

if git_location
  require 'grit'
  corl_require(util_dir, :git)
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
Dir.glob(File.join(mixin_config_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(mixin_action_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(macro_dir, '*.rb')).each do |file|
  require file
end

#---

# Include bootstrap classes
corl_require(core_dir, :errors)
corl_require(core_dir, :codes)
corl_require(util_dir, :data)
corl_require(core_dir, :config)
corl_require(util_dir, :interface) 
corl_require(core_dir, :core) 

#---

# Include core utilities
[ :liquid, 
  :cli, 
  :disk, 
  :package, 
  :shell, 
  :ssh 
].each do |name| 
  corl_require(util_dir, name)
end

# Include core systems
corl_require(core_dir, :corl)
corl_require(core_dir, :gems)
corl_require(core_dir, :manager)
corl_require(plugin_dir, :base)
corl_require(core_dir, :plugin)
corl_require(core_dir, :facade)

#-------------------------------------------------------------------------------
# CORL initialization

CORL.initialize
