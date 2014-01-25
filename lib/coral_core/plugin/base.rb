
module Coral
module Plugin
class Base < Core
  
  # All Plugin classes should directly or indirectly extend Base
  
  def initialize(type, provider, options)
    config = Config.ensure(options)
    name   = Util::Data.ensure_value(config.delete(:name), provider)
    
    logger.debug("Setting #{type} plugin #{name} meta data")
    set_meta(config.delete(:meta, Config.new))
    
    logger.debug("Passing execution to core: #{config.export.inspect}")
    super(config)
    
    self.name = name
    
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
  # Plugin operations
    
  def normalize
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
            info[:provider] = Plugin.type_default(type)
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
end
end
end
