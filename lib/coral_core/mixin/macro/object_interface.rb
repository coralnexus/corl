
# Should be included via extend
#
# extend Mixin::Macro::ObjectInterface
#

module Coral
module Mixin
module Macro
module ObjectInterface
  
  # requires Mixin::SubConfig
  # requires Mixin::Settings

  #-----------------------------------------------------------------------------
  # Object collections
  
  @@object_types = {}

  #---
  
  def object_collection(_type, _method_options = {})
    _method_config = Config.ensure(_method_options)
    
    _plural      = _method_config.init(:plural, "#{_type}s").get(:plural)
    
    unless _ensure_proc = _method_config.get(:ensure_proc, false)
      _ensure_proc = Proc.new {|name, options = {}| options }
    end
    _delete_proc = _method_config.get(:delete_proc)
    _search_proc = _method_config.get(:search_proc)
    
    @@object_types[_type] = _method_config
    
    logger.debug("Creating new object collection #{_type} with: #{_method_config.inspect}")
    
    #---------------------------------------------------------------------------
    
    object_utilities
    
    #---
    
    unless respond_to? :each_object!
      logger.debug("Defining object interface method: each_object!")
      
      define_method :each_object! do |object_types = nil|
        each_object_type!(object_types) do |type, plural, options|
          logger.debug("Processing object type #{type}/#{plural} with: #{options.inspect}")
          
          send(plural).each do |name, obj|
            logger.debug("Processing object: #{name}")
            yield(type, name, obj)  
          end 
        end  
      end
    end
     
    #---------------------------------------------------------------------------
    
    logger.debug("Defining object interface method: #{_type}_config")
    
    define_method "#{_type}_config" do |name = nil|
      Config.new( name ? get([ _plural, name ], {}) : get(_plural, {}) )
    end
  
    #---
    
    logger.debug("Defining object interface method: #{_type}_setting")
    
    define_method "#{_type}_setting" do |name, property, default = nil, format = false|
      get([ _plural, name, property ], default, format)
    end
  
    #---
    
    logger.debug("Defining object interface method: #{_plural}")
    
    define_method "#{_plural}" do
      _get(_plural, {})
    end
    
    #---
    
    logger.debug("Defining object interface method: init_#{_plural}")
  
    define_method "init_#{_plural}" do
      data = hash(_search_proc.call) if _search_proc
      data = get_hash(_plural) unless data
      
      logger.debug("Initializing object data: #{data.inspect}")
      
      symbol_map(data).each do |name, options|
        if name != :settings
          options[:object_container] = self
          
          logger.debug("Initializing object: #{name}")
          
          obj = _ensure_proc.call(name, options)
          _set([ _plural, name ], obj)
        end
      end
    end
  
    #---
    
    logger.debug("Defining object interface method: set_#{_plural}")

    define_method "set_#{_plural}" do |data = {}|
      data = Config.ensure(data).export
    
      send("clear_#{_plural}")
      set(_plural, data)
      
      logger.debug("Setting #{_plural}")
    
      data.each do |name, options|
        options[:object_container] = self
        
        logger.debug("Setting #{_type} #{name}: #{options.inspect}")
        
        obj = _ensure_proc.call(name, options)
        _set([ _plural, name ], obj)
      end
      self
    end

    #---
    
    logger.debug("Defining object interface method: #{_type}")
    
    define_method "#{_type}" do |name|
      _get([ _plural, name ])
    end
    
    #---
    
    logger.debug("Defining object interface method: set_#{_type}")

    define_method "set_#{_type}" do |name, options = {}|
      options = Config.ensure(options).export
      
      set([ _plural, name ], options)
    
      options[:object_container] = self
      
      logger.debug("Setting #{_type} #{_name}: #{options.inspect}")
      
      obj = _ensure_proc.call(name, options) 
      _set([ _plural, name ], obj)
      self
    end
  
    #---
    
    logger.debug("Defining object interface method: set_#{_type}_setting")
  
    define_method "set_#{_type}_setting" do |name, property, value = nil|
      set([ _plural, name, property ], value)
      self
    end
    
    #---
    
    logger.debug("Defining object interface method: delete_#{_type}")

    define_method "delete_#{_type}" do |name|
      obj = send(_type, name)
      
      logger.debug("Deleting #{_type} #{name}")
    
      delete([ _plural, name ])
      _delete([ _plural, name ])
    
      _delete_proc.call(obj) if _delete_proc
      self
    end
  
    #---
    
    logger.debug("Defining object interface method: delete_#{_type}_setting")
  
    define_method "delete_#{_type}_setting" do |name, property|
      logger.debug("Deleting #{name} property: #{property}")
      
      delete([ _plural, name, property ])
      self
    end
  
    #---
    
    logger.debug("Defining object interface method: clear_#{_plural}")
  
    define_method "clear_#{_plural}" do
      _get(_plural).keys.each do |name|
        logger.debug("Clearing #{_type} #{name}")
        
        send("delete_#{_type}", name)
      end
      self
    end    
        
    #---------------------------------------------------------------------------
    
    logger.debug("Defining object interface method: search_#{_type}")
  
    define_method "search_#{_type}" do |name, keys, default = '', format = false|
      obj_config = send("#{_type}_config", name)
      search_object(obj_config, keys, default, format)
    end
  end

  #-----------------------------------------------------------------------------
  # Utilities
  
  def object_utilities
    
    unless respond_to? :foreach_object_type!
      logger.debug("Defining object utility method: foreach_object_type!")
      
      define_method :foreach_object_type! do |object_types = nil, filter_proc = nil|
        object_types = @@object_types.keys unless object_types
        object_types = [ object_types ] unless object_types.is_a?(Array)
      
        object_types.keys.each do |type|
          logger.debug("Processing object type: #{type}")
          
          unless filter_proc && ! filter_proc.call(type, @@object_types[type])
            plural = @@object_types[type][:plural]
            
            logger.debug("Passing: #{@@object_types[type].inspect}")
            yield(type, plural, @@object_types[type])
          end
        end  
      end
    end
           
    #---
    
    unless respond_to? :init_objects
      logger.debug("Defining object utility method: init_objects")
      
      define_method :init_objects do |object_types = nil, filter_proc = nil|
        logger.debug("Initializing object collection")
        
        foreach_object_type!(object_types, filter_proc) do |type, plural, options|
          send("init_#{plural}")  
        end   
      end
    end
    
    #---
    
    unless respond_to? :clear_objects
      logger.debug("Defining object utility method: clear_objects")
      
      define_method :clear_objects do |object_types = nil, filter_proc = nil|
        logger.debug("Clearing object collection")
        
        foreach_object_type!(object_types, filter_proc) do |type, plural, options|
          send("clear_#{plural}")  
        end
      end
    end
    
    #---------------------------------------------------------------------------
  
    unless respond_to? :search_object
      logger.debug("Defining object utility method: search_object")
        
      define_method :search_object do |obj_config, keys, default = '', format = false|
        obj_config = Marshal.load(Marshal.dump(obj_config))
        value      = obj_config.get(keys)
        
        logger.debug("Searching object properties: #{obj_config.inspect}")
        
        if ! value || value.is_a?(Hash)
          settings = {}
    
          keys = [ keys ] unless keys.is_a?(Array)
          temp = keys.dup
          
          logger.debug("Searching object keys: #{keys.inspect}")
          
          logger.debug("Searching specialized settings")      
          until temp.empty? do
            if obj_settings = obj_config.delete([ temp, :settings ])
              array(obj_settings).each do |group_name|
                if group_settings = Marshal.load(Marshal.dump(settings(group_name)))
                  settings = Util::Data.merge([ group_settings.dup, settings ], true)  
                end
              end            
            end
            temp.pop
          end
    
          logger.debug("Specialized settings found: #{settings.inspect}") 
          logger.debug("Searching general settings") 
      
          if obj_settings = obj_config.delete(:settings)
            array(obj_settings).each do |group_name|
              if group_settings = Marshal.load(Marshal.dump(settings(group_name)))
                settings = Util::Data.merge([ group_settings, settings ], true)  
              end
            end            
          end 
          
          logger.debug("Final settings found: #{settings.inspect}")  
        
          unless settings.empty?
            final_config = Config.new(Util::Data.merge([ settings, obj_config.export ], true))
            value        = final_config.get(keys)
            
            logger.debug("Final configuration: #{final_config.export.inspect}")
          end
          
          value = default if Util::Data.undef?(value)
        end
        
        logger.debug("Final value found (format: #{format.inspect}): #{value.inspect}")
        filter(value, format)
      end
    end
    
    #---------------------------------------------------------------------------
    # Configuration loading saving
    
    unless respond_to? :load
      logger.debug("Defining object utility method: load")
      
      define_method :load do |options = {}|
        logger.debug("Loading configuration if possible") 
        if config.respond_to?(:load)
          clear_objects  
          config.load(options)    
          init_objects
        end
        self  
      end
    end
    
    #---
    
    unless respond_to? :save
      logger.debug("Defining object utility method: save")
      
      define_method :save do |options = {}|
        logger.debug("Saving configuration if possible") 
        config.save(options) if config.respond_to?(:save)
        self  
      end
    end    
  end
end
end
end
end
