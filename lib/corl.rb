
#*******************************************************************************
# CORL (Coral Orchestration and Research Library)
#
# built on Nucleon (github.com/coralnexus/nucleon)
#
# A framework that provides a simple foundation for growing organically in
# the cloud.
#
# Author::    Adrian Webb (mailto:adrian.webb@coralnexus.com)
# License::   Apache License v2

#-------------------------------------------------------------------------------
# Top level properties

lib_dir           = File.dirname(__FILE__)
core_dir          = File.join(lib_dir, 'core')
mod_dir           = File.join(core_dir, 'mod')
mixin_dir         = File.join(core_dir, 'mixin')
mixin_action_dir  = File.join(mixin_dir, 'action')
mixin_machine_dir = File.join(mixin_dir, 'machine')
macro_dir         = File.join(mixin_dir, 'macro')
util_dir          = File.join(core_dir, 'util')
mod_dir           = File.join(core_dir, 'mod')
vagrant_dir       = File.join(core_dir, 'vagrant')

vagrant_exists    = defined?(Vagrant) == 'constant' && Vagrant.class == Module

#-------------------------------------------------------------------------------
# Daemonize if needed
#
# This must come before Nucleon is loaded due to a huge bug in Celluloid that
# prevents it from working in parallel mode if Celluloid actors are already
# initialized before daemonization.

# Must be an agent that is running locally

# For the record, this stinks, it's ugly, and I hate it, but the maintainer
# of Celluloid does not seem to regard it as important enough to fix.
#
# https://github.com/celluloid/celluloid/issues/97
#
# For agent options processed here, see lib/core/plugin/agent.rb
#
unless vagrant_exists
  action_start_index = 0

  if ARGV[action_start_index].to_sym == :agent
    remote_exec            = false

    log                    = true
    truncate_log           = true

    log_file               = nil
    agent_provider         = []
    process_log_file_value = false

    first_option_found     = false

    # Argument processing
    ARGV[(action_start_index + 1)..-1].each do |arg|
      first_option_found = true if arg[0] == '-'

      if arg =~ /^\-\-nodes\=?/
        remote_exec = true
      elsif arg == "--no-log"
        log = false
      elsif arg == "--no-truncate_log"
        truncate_log = false
      elsif arg =~ /^\-\-log_file(?=\=(.*))?/
        if $1
          log_file = $1
        else
          process_log_file_value = true
        end
      elsif process_log_file_value
        log_file               = arg
        process_log_file_value = false
      elsif ! first_option_found
        agent_provider << arg
      end
    end

    # TODO: Need better way to share with base agent default log file. (mixin?)
    log_file = "/var/log/corl/agent_#{agent_provider.join('_')}.log" unless log_file

    unless remote_exec
      # Daemonize process
      Process.daemon

      # Log all output, or not
      if log
        FileUtils.mkdir_p('/var/log/corl')
        File.write(log_file, '') if truncate_log

        $stderr.reopen(log_file, 'a')
        $stdout.reopen($stderr)
        $stdout.sync = $stderr.sync = true
      end
    end
  end
end

#-------------------------------------------------------------------------------
# CORL requirements

$:.unshift(lib_dir) unless $:.include?(lib_dir) || $:.include?(File.expand_path(lib_dir))

require 'nucleon_base'
CORL = Nucleon

require 'hiera'
require 'facter'

#-------------------------------------------------------------------------------
# Localization

# TODO: Make this dynamically settable

I18n.enforce_available_locales = false
I18n.load_path << File.expand_path(File.join('..', 'locales', 'en.yml'), lib_dir)

#-------------------------------------------------------------------------------
# Include CORL libraries

# Monkey patches (depreciate as fast as possible)

#---

# Mixins for classes
Dir.glob(File.join(mixin_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(mixin_action_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(mixin_machine_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(macro_dir, '*.rb')).each do |file|
  require file
end

#---

# Include CORL utilities
[ :puppet ].each do |name|
  nucleon_require(util_dir, name)
end

# Special errors
nucleon_require(core_dir, :errors)

#-------------------------------------------------------------------------------
# Class and module additions / updates

module Nucleon
  class Config
    extend Mixin::Lookup
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
nucleon_require(core_dir, :build)
nucleon_require(core_dir, :plugin)

# Include Vagrant plugins (only include if running inside Vagrant)
nucleon_require(vagrant_dir, :plugins) if vagrant_exists


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

  reload(true, :corl) do |op, manager|
    if op == :define
      manager.define_types :CORL, {
        :configuration => :file,      # Core
        :network       => :corl,      # Cluster
        :node          => :local,     # Cluster
        :machine       => :physical,  # Cluster
        :builder       => :package,   # Cluster
        :provisioner   => :puppetnode # Cluster
      }
    end
  end
end
