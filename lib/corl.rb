
#*******************************************************************************
# CORL (Cluster Orchestration and Research Library)
#
# built on Nucleon (github.com/coralnexus/nucleon)
#
# A framework that provides a simple foundation for growing organically in 
# the cloud.
#
# Author::    Adrian Webb (mailto:adrian.webb@coralnexus.com)
# License::   GPLv3

#-------------------------------------------------------------------------------
# Top level properties 

lib_dir          = File.dirname(__FILE__)
core_dir         = File.join(lib_dir, 'core')
mixin_dir        = File.join(core_dir, 'mixin')
mixin_action_dir = File.join(mixin_dir, 'action')
macro_dir        = File.join(mixin_dir, 'macro')
util_dir         = File.join(core_dir, 'util')
mod_dir          = File.join(core_dir, 'mod')
 
#-------------------------------------------------------------------------------
# CORL requirements

$:.unshift(lib_dir) unless $:.include?(lib_dir) || $:.include?(File.expand_path(lib_dir))

#---
  
require 'rubygems'

require 'nucleon_base'
CORL = Nucleon

require 'hiera'
require 'facter'
require 'puppet'

#-------------------------------------------------------------------------------
# Localization

# TODO: Make this dynamically settable

I18n.enforce_available_locales = false
I18n.load_path << File.expand_path(File.join('..', 'locales', 'en.yml'), lib_dir)

#-------------------------------------------------------------------------------
# Include CORL libraries

# Mixins for classes
Dir.glob(File.join(mixin_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(mixin_action_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(macro_dir, '*.rb')).each do |file|
  require file
end

#---

# Include CORL utilities
#[].each do |name| 
#  nucleon_require(util_dir, name)
#end

# Special errors
nucleon_require(core_dir, :errors)

#-------------------------------------------------------------------------------
# Class and module additions / updates

module CORL
  class Config
    include Mixin::Lookup  
  end
  
  #---
  
  module Plugin
    class Base
      extend Mixin::Macro::NetworkSettings    
    end
  end
end

#-------------------------------------------------------------------------------
# Include CORL plugins

# Include facade
nucleon_require(core_dir, :facade)

# Include CORL core plugins
nucleon_require(core_dir, :plugin)

#-------------------------------------------------------------------------------
# CORL interface

module CORL
 
  def self.VERSION
    File.read(File.join(File.dirname(__FILE__), '..', 'VERSION'))  
  end
  
  #-----------------------------------------------------------------------------
  # CORL initialization
  
  def self.lib_path
    File.dirname(__FILE__)
  end
  
  #---  

  reload(true) do |op, manager|
    if op == :define
      manager.define_namespace :CORL
    
      manager.define_type :configuration => :file,      # Core
                          :network       => :default,   # Cluster
                          :node          => :local,     # Cluster
                          :machine       => :physical,  # Cluster
                          :provisioner   => :puppetnode # Cluster
    end
  end
end
