
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
plugin_dir       = File.join(core_dir, 'plugin')
 
#-------------------------------------------------------------------------------
# CORL requirements

$:.unshift(lib_dir) unless $:.include?(lib_dir) || $:.include?(File.expand_path(lib_dir))

#---
  
require 'rubygems'

require 'nucleon'

require 'tmpdir'
require 'sshkey'

require 'hiera'
require 'facter'

#---

# TODO: Make this dynamically settable

I18n.enforce_available_locales = false
I18n.load_path << File.expand_path(File.join('..', 'locales', 'en.yml'), lib_dir)

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
Dir.glob(File.join(mixin_action_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(macro_dir, '*.rb')).each do |file|
  require file
end

#---

# Include CORL utilities
[ :ssh 
].each do |name| 
  nucleon_require(util_dir, name)
end

# Include core systems
nucleon_require(core_dir, :facade)
nucleon_require(core_dir, :plugin)

#-------------------------------------------------------------------------------
# CORL initialization

Nucleon.define_namespace :CORL
Nucleon.reload
