
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

lib_dir          = File.dirname(__FILE__)
core_dir         = File.join(lib_dir, 'coral_core')
mixin_dir        = File.join(core_dir, 'mixin')
mixin_config_dir = File.join(mixin_dir, 'config')
mixin_cli_dir    = File.join(mixin_dir, 'cli')
macro_dir        = File.join(mixin_dir, 'macro')
util_dir         = File.join(core_dir, 'util')
mod_dir          = File.join(core_dir, 'mod')
plugin_dir       = File.join(core_dir, 'plugin')
 
#-------------------------------------------------------------------------------
# Coral requirements

git_location = coral_locate('git')

$:.unshift(lib_dir) unless $:.include?(lib_dir) || $:.include?(File.expand_path(lib_dir))

#---
  
require 'rubygems'

require 'i18n'
require 'log4r'
require 'deep_merge'
require 'yaml'
require 'multi_json'
require 'digest/sha1'
require 'optparse'

#---

# TODO: Make this dynamically settable

I18n.enforce_available_locales = false
I18n.load_path << File.expand_path(File.join('..', 'locales', 'en.yml'), lib_dir)

#---

if git_location
  require 'grit'
  coral_require(util_dir, :git)
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
Dir.glob(File.join(mixin_cli_dir, '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(macro_dir, '*.rb')).each do |file|
  require file
end

#---

# Include bootstrap classes
coral_require(util_dir, :data)
coral_require(core_dir, :config)
coral_require(util_dir, :interface) 
coral_require(core_dir, :core) 

#---

# Include core utilities
[ :cli, :disk, :process, :shell ].each do |name| 
  coral_require(util_dir, name)
end

# Include core systems
coral_require(plugin_dir, :base)
coral_require(core_dir, :plugin)

# Include extras
[ :resource ].each do |name|
  coral_require(core_dir, name)
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
  
  #-----------------------------------------------------------------------------
  
  def self.ui
    return Core.ui
  end
  
  #---
  
  def self.logger
    return Core.logger
  end
   
  #-----------------------------------------------------------------------------

  @@config_file = 'coral.json'
  
  #---
    
  def self.config_file=file_name
    @@config_file = file_name
  end
  
  #---
  
  def self.config_file
    return @@config_file
  end
  
  #-----------------------------------------------------------------------------
  # Initialization
  
  @@initialized = false
  
  def self.initialize
    unless @@initialized
      current_time = Time.now
      
      logger.info("Initializing the Coral plugin system at #{current_time}")
      Config.set_property('time', current_time.to_i)
      
      Plugin.initialize do
        begin
          logger.info("Registering Coral plugin defined within Puppet modules")
          
          # Include Coral plugins
          Puppet::Node::Environment.new.modules.each do |mod|
            lib_path = File.join(mod.path, 'lib', 'coral')
            
            logger.debug("Registering Puppet module at #{lib_path}")
            Plugin.register(lib_path)
          end
        rescue
        end
        
        logger.info("Finished initializing Coral plugin system at #{Time.now}")
      end
            
      @@initialized = true
    end    
  end
  
  #---
  
  def self.initialized?
    return @@initialized
  end
    
  #-----------------------------------------------------------------------------
  # Plugins
  
  Plugin.define_type :configuration => :file,
                     :network       => :default, 
                     :node          => :rackspace,
                     :machine       => :fog,
                     :command       => :shell,
                     :event         => :regex,
                     :template      => :json,
                     :translator    => :json,
                     :project       => :git,
                     :action        => :create,
                     :extension     => nil
                     
  #-----------------------------------------------------------------------------
  # Plugin interface (facade)
  
  def self.plugin(type, provider, options = {})
    default_provider = Plugin.type_default(type)
    
    if options.is_a?(Hash) || options.is_a?(Coral::Config)
      config   = Config.ensure(options)
      provider = config.get(:provider, provider)
      name     = config.get(:name, nil)
      options  = config.export
    end
    provider = default_provider unless provider # Sanity checking (see plugins)
    
    logger.info("Fetching plugin #{type} provider #{provider} at #{Time.now}")
    logger.debug("Plugin options: #{options.inspect}")
    
    if name
      logger.debug("Looking up existing instance of #{name}")
      
      existing_instance = Plugin.get_instance(type, name)
      logger.info("Using existing instance of #{type}, #{name}") if existing_instance
    end
    
    return existing_instance if existing_instance
    return Plugin.create_instance(type, provider, options)
  end
  
  #---
  
  def self.plugins(type, data, build_hash = false, keep_array = false)
    logger.info("Fetching multiple plugins of #{type} at #{Time.now}")
    
    group = ( build_hash ? {} : [] )
    klass = class_const([ :coral, :plugin, type ])    
    data  = klass.build_info(type, data) if klass.respond_to?(:build_info)
    
    logger.debug("Translated plugin data: #{data.inspect}")
    
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
  
  def self.get_plugin(type, name)
    return Plugin.get_instance(type, name)
  end
  
  #---
  
  def self.remove_plugin(plugin)
    return Plugin.remove_instance(plugin)
  end
  
  #-----------------------------------------------------------------------------
  # Core plugin type facade
  
  def self.configuration(options, provider = nil)
    return plugin(:configuration, provider, options)
  end
  
  def self.configurations(data, build_hash = false, keep_array = false)
    return plugins(:configuration, data, build_hash, keep_array)
  end
   
  #---
   
  def self.network(name, options = {}, provider = nil)
    return plugin(:network, provider, Config.ensure(options).import({ :name => name }))
  end
  
  def self.networks(data, build_hash = false, keep_array = false)
    return plugins(:network, data, build_hash, keep_array)
  end
   
  #---
  
  def self.node(name, options = {}, provider = nil)
    return plugin(:node, provider, Config.ensure(options).import({ :name => name }))
  end
  
  def self.nodes(data, build_hash = false, keep_array = false)
    return plugins(:node, data, build_hash, keep_array)
  end
   
  #---
  
  def self.machine(options = {}, provider = nil)
    return plugin(:machine, provider, options)
  end
  
  def self.machines(data, build_hash = false, keep_array = false)
    return plugins(:machine, data, build_hash, keep_array)
  end
  
  #---
  
  def self.project(options, provider = nil)
    return plugin(:project, provider, options)
  end
  
  def self.projects(data, build_hash = false, keep_array = false)
    return plugins(:project, data, build_hash, keep_array)
  end
  
  #---
  
  def self.command(options, provider = nil)
    return plugin(:command, provider, options)
  end
  
  def self.commands(data, build_hash = false, keep_array = false)
    return plugins(:command, data, build_hash, keep_array)
  end
    
  #---
  
  def self.event(options, provider = nil)
    return plugin(:event, provider, options)
  end
  
  def self.events(data, build_hash = false, keep_array = false)
    return plugins(:event, data, build_hash, keep_array)
  end
  
  #---
  
  def self.template(options, provider = nil)
    return plugin(:template, provider, options)
  end
  
  def self.templates(data, build_hash = false, keep_array = false)
    return plugins(:template, data, build_hash, keep_array)
  end
   
  #---
  
  def self.translator(options, provider = nil)
    return plugin(:translator, provider, options)
  end
  
  def self.translators(data, build_hash = false, keep_array = false)
    return plugins(:translator, data, build_hash, keep_array)
  end
  
  #---
  
  def self.action(provider, args = [], quiet = false)
    return plugin(:action, provider, { :args => args, :quiet => quiet })
  end
  
  def self.actions(data, build_hash = false, keep_array = false)
    return plugins(:action, data, build_hash, keep_array)  
  end
    
  #---
  
  def self.extension(provider)
    return plugin(:extension, provider, {})
  end
  
  #-----------------------------------------------------------------------------
  # Plugin extensions
   
  def self.exec!(method, options = {})
    return Plugin.exec!(method, options) do |op, results|
      results = yield(op, results) if block_given?
      results
    end
  end
       
  #-----------------------------------------------------------------------------
  # External execution
   
  def self.run
    begin
      logger.debug("Running contained process at #{Time.now}")
      
      initialize
      yield
      
    rescue Exception => e
      logger.error("Coral run experienced an error! Details:")
      logger.error(e.inspect)
      logger.error(e.message)
      logger.error(Util::Data.to_yaml(e.backtrace))
  
      ui.error(e.message) if e.message
      raise
    end
  end
    
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.class_name(name, separator = '::', want_array = FALSE)
    components = []
    
    case name
    when String, Symbol
      components = name.to_s.split(separator)
    when Array
      components = name 
    end
    
    components.collect! do |value|
      value.to_s.strip.capitalize  
    end
    
    if want_array
      return components
    end    
    return components.join(separator)
  end
  
  #---
  
  def self.class_const(name, separator = '::')
    components = class_name(name, separator, TRUE)
    constant   = Object
    
    components.each do |component|
      constant = constant.const_defined?(component) ? 
                  constant.const_get(component) : 
                  constant.const_missing(component)
    end
    
    return constant
  end
  
  #---
  
  def self.sha1(data)
    return Digest::SHA1.hexdigest(Util::Data.to_json(data, false))
  end  
end

#-------------------------------------------------------------------------------
# Coral initialization

Coral.initialize
