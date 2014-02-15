
module Coral
module Plugin
class Base < Core
  
  include Mixin::Lookup
  include Celluloid
  
  #---
  
  # All Plugin classes should directly or indirectly extend Base
  
  def initialize(type, provider, options)
    config = Util::Data.clean(Config.ensure(options))
    name   = Util::Data.ensure_value(config.delete(:name), provider)
       
    set_meta(config.delete(:meta, Config.new))
    
    # No logging statements aove this line!!
    super(config.import({ :logger => "#{plugin_type}->#{plugin_provider}" }))
    self.name = name
    
    logger.debug("Set #{type} plugin #{name} meta data: #{meta.inspect}")    
    logger.debug("Normalizing #{type} plugin #{name}")
    normalize
  end
  
  #---
  
  def initialized?(options = {})
    return true  
  end
  
  #---
  
  def method_missing(method, *args, &block)  
    return nil  
  end
  
  #---
  
  def inspect
    "#<#{self.class}: #{name}>"
  end
  
  #-----------------------------------------------------------------------------
  # Property accessor / modifiers
  
  def name
    return @name
  end
  
  #---
  
  def name=name
    @name = string(name)
  end
  
  #---
  
  def meta
    return @meta
  end
  
  #---
  
  def set_meta(meta)
    @meta = Config.ensure(meta)
  end
  
  #---
  
  def plugin_type
    return meta.get(:type)
  end
  
  #---
  
  def plugin_provider
    return meta.get(:provider)
  end
  
  #---
  
  def plugin_directory
    return meta.get(:directory)
  end
  
  #---
  
  def plugin_file
    return meta.get(:file)
  end
  
  #---
  
  def plugin_instance_name
    return meta.get(:instance_name)
  end
  
  #---
  
  def plugin_parent=parent
    meta.set(:parent, parent) if parent.is_a?(Coral::Plugin::Base)
  end
  
  #---
  
  def plugin_parent
    return meta.get(:parent)
  end

  #-----------------------------------------------------------------------------
  # Status codes
    
  def code
    Coral.code
  end
  
  def codes(*codes)
    Coral.codes(*codes)
  end

  #---
  
  def status=status
    meta.set(:status, status)
  end
  
  def status
    meta.get(:status, code.unknown_status)
  end

  #-----------------------------------------------------------------------------
  # Plugin operations
    
  def normalize
  end
  
  #-----------------------------------------------------------------------------
  # Extensions
  
  def hook_method(hook)
    "#{plugin_type}_#{plugin_provider}_#{hook}"  
  end
  
  #---
  
  def extension(hook, options = {})
    method = hook_method(hook)
    
    logger.debug("Executing plugin hook #{hook} (#{method})")
    
    return Manager.connection.exec(method, Config.ensure(options).defaults({ :extension_type => :base }).import({ :plugin => self })) do |op, results|
      results = yield(op, results) if block_given?
      results
    end
  end
  
  #---
  
  def extended_config(type, options = {})
    config = Config.ensure(options)
    
    logger.debug("Generating #{type} extended configuration from: #{config.export.inspect}")
      
    extension("#{type}_config", Config.new(config.export).import({ :extension_type => :config })) do |op, results|
      if op == :reduce
        results.each do |provider, result|
          config.defaults(result)
        end
        nil
      else
        hash(results)
      end
    end    
    config.delete(:extension_type)
     
    logger.debug("Final extended configuration: #{config.export.inspect}")   
    config 
  end
  
  #---
  
  def extension_check(hook, options = {})
    config = Config.ensure(options)
    
    logger.debug("Checking extension #{plugin_provider} #{hook} given: #{config.export.inspect}")
    
    success = extension(hook, config.import({ :extension_type => :check })) do |op, results|
      if op == :reduce
        ! results.values.include?(false)
      else
        results ? true : false
      end
    end
    
    success = success.nil? || success ? true : false
    
    logger.debug("Extension #{plugin_provider} #{hook} check result: #{success.inspect}")  
    success
  end
  
  #---
  
  def extension_set(hook, value, options = {})
    config = Config.ensure(options)
    
    logger.debug("Setting extension #{plugin_provider} #{hook} value given: #{value.inspect}")
    
    extension(hook, config.import({ :value => value, :extension_type => :value })) do |op, results|
      if op == :process
        value = results unless results.nil?  
      end
    end
    
    logger.debug("Extension #{plugin_provider} #{hook} set value to: #{value.inspect}")  
    value
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info(type, data)  
    plugins = []
        
    if data.is_a?(Hash)
      data = [ data ]
    end
    
    logger.debug("Building plugin list of #{type} from data: #{data.inspect}")
    
    if data.is_a?(Array)
      data.each do |info|
        unless Util::Data.empty?(info)
          info = translate(info)
          
          if Util::Data.empty?(info[:provider])
            info[:provider] = Manager.connection.type_default(type)
          end
          
          logger.debug("Translated plugin info: #{info.inspect}")
          
          plugins << info
        end
      end
    end
    return plugins
  end
  
  #---

  def self.translate(data)
    logger.debug("Translating data to internal plugin structure: #{data.inspect}")
    return ( data.is_a?(Hash) ? symbol_map(data) : {} )
  end
  
  #---
  
  def self.init_plugin_collection
    logger.debug("Initializing plugin collection interface at #{Time.now}")
    
    include Mixin::Settings
    include Mixin::SubConfig
    
    extend Mixin::Macro::PluginInterface
  end
  
  #---
  
  def safe_exec(return_result = true)
    begin
      result = yield
      return result if return_result
      return true
      
    rescue Exception => e
      logger.error(e.inspect)
      logger.error(e.message)
      
      ui.error(e.message, { :prefix => false }) if e.message
    end
    return false
  end
end
end
end
