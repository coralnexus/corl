
# Should be included via extend
#
# extend Mixin::ObjectInterface
#

module Coral
module Mixin
module ObjectInterface
  
  include Mixin::SubConfig
  include Mixin::Settings

  #-----------------------------------------------------------------------------
  # Object collections
  
  @@object_types = {}
  
  #---
  
  def object_collection(type, plural, ensure_proc, delete_proc = nil, search_proc = nil)
    @@object_types[type] = {
      :plural      => plural,
      :ensure_proc => ensure_proc,
      :delete_proc => delete_proc,
      :search_proc => search_proc
    }
    
    #---
    
    object_utilities
    
    #---
    
    define_method "#{type}_info" do |name = nil|
      symbol_map( name ? get([ plural, name ], {}) : get(plural, {}) )
    end
  
    #---
    
    define_method "#{type}_setting" do |name, property, default = nil, format = false|
      get([ plural, name, property ], default, format)
    end
  
    #---
    
    define_method "search_#{type}" do |name, keys, default = '', format = false|
      search(type, name, keys, default, format)
    end
    
    #---
    
    define_method "#{plural}" do
      _get(plural, {})
    end
    
    #---
  
    define_method "init_#{plural}" do
      data = search_proc.call if search_proc
      data = get_hash(plural) unless data
      
      symbol_map(data).each do |name, info|
        if name != :settings
          info[:object_container] = self
          
          obj = ensure_proc.call(name, info)
          _set([ plural, name ], obj)
        end
      end
    end
  
    #---

    define_method "set_#{plural}" do |data = {}|
      data = symbol_map(hash(data))
    
      send("clear_#{plural}")
      set(plural, data)
    
      data.each do |name, info|
        info[:object_container] = self
        
        obj = ensure_proc.call(name, info)
        _set([ plural, name ], obj)
      end
      self
    end

    #---
    
    define_method "#{type}" do |name|
      _get([ plural, name ])
    end
    
    #---

    define_method "set_#{type}" do |name, info = {}|
      info = symbol_map(hash(info))
      
      set([ plural, name ], info)
    
      info[:object_container] = self
      
      obj = ensure_proc.call(name, info) 
      _set([ plural, name ], obj)
      self
    end
  
    #---
  
    define_method "set_#{type}_setting" do |name, property, value = nil|
      set([ plural, name, property ], value)
      self
    end
    
    #---

    define_method "delete_#{type}" do |name|
      obj = send(type, name)
    
      delete([ plural, name ])
      _delete([ plural, name ])
    
      delete_proc.call(obj) if delete_proc
      self
    end
  
    #---
  
    define_method "delete_#{type}_setting" do |name, property|
      delete([ plural, name, property ])
      self
    end
  
    #---
  
    define_method "clear_#{plural}" do
      _get(plural).keys.each do |name|
        send("delete_#{type}", name)
      end
      self
    end     
  end
  
  #---
  
  def plugin_collection(type, plural = nil, search_proc = nil)
    plural = "#{type}s" unless plural
    
    object_collection(type, plural, 
      Proc.new { |provider, options| Coral.plugin(type, provider, options) },
      Proc.new { |plugin| Coral.remove_plugin(plugin) },
      search_proc
    )
    @@object_types[type][:plugin] = true    
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  @@utilities_initialized = false
  
  #---

  def object_utilities
    
    return if @@utilities_initialized
    @@utilities_initialized = true
    
    #---
    
    define_method :foreach_object_type! do |object_types = nil, plugins_only = false|
      object_types = @@object_types.keys unless object_types
      object_types = [ object_types ] unless object_types.is_a?(Array)
      
      object_types.keys.each do |type|
        unless plugins_only && ! @@object_types[type][:plugin]
          plural = @@object_types[type][:plural]
          yield(type, plural, @@object_types[type])
        end
      end  
    end
    
    #---
    
    define_method :foreach_object! do |object_types = nil|
      foreach_object_type!(object_types, false) do |type, plural, options|
        send(plural).each do |name, obj|
          yield(type, name, obj)  
        end 
      end  
    end
    
    #---
    
    define_method :foreach_plugin! do |plugin_types = nil|
      foreach_object_type!(plugin_types, true) do |type, plural, options|
        send(plural).each do |name, plugin|
          yield(type, name, plugin)  
        end 
      end  
    end
       
    #---
    
    define_method :init_objects do |object_types = nil|
      foreach_object_type!(object_types) do |type, plural, options|
        send("init_#{plural}")  
      end   
    end
    
    #---
    
    define_method :clear_objects do |object_types = nil|
      foreach_object_type!(object_types) do |type, plural, options|
        send("clear_#{plural}")  
      end
    end

    #---------------------------------------------------------------------------
  
    #
    # search(:provisioner, :puppet, [:resources, :defaults, :coral_base_git])
    # search(:provisioner, :puppet, [:resources, :profiles, :coral_base])
    # search(:provisioner, :puppet, [:nodes, :coral_base])
    # search(:provisioner, :puppet, [:modules, :stdlib])
    # search(:config, :json, [:identity, :url])
    #   
    define_method :search do |type, name, keys, default = '', format = false|
      type_config = Config.new(send("#{type}_info", name))
      value       = type_config.get(keys)
       
      return filter(value, format) if value && ! value.is_a?(Hash)
    
      settings = {}
    
      keys     = [ keys ] unless keys.is_a?(Array)
      temp     = keys.dup
      
      until temp.empty? do
        if type_settings = type_config.delete([ temp, :settings ])
          array(type_settings).each do |group_name|
            if group_settings = settings(group_name)
              settings = Util::Data.merge([ group_settings, settings ], true)  
            end
          end            
        end
        temp.pop
      end
    
      if type_settings = type_config.delete(:settings)
        array(type_settings).each do |group_name|
          if group_settings = settings(group_name)
            settings = Util::Data.merge([ group_settings, settings ], true)  
          end
        end            
      end    
        
      unless settings.empty?
        if value
          value = Util::Data.merge([ settings, value ], true)         
        else
          value = settings[keys.last] if settings.has_key?(keys.last)
        end
      end
    
      value = default if Util::Data.undef?(value)
      return filter(value, format)
    end
    
    #---------------------------------------------------------------------------
    # Configuration loading saving
    
    define_method :load do |options = {}|
      if config.respond_to?(:load)
        clear_objects  
        config.load(options)    
        init_objects
      end
      return self  
    end
    
    #---
    
    define_method :save do |options = {}|
      config.save(options) if config.respond_to?(:save)
      return self  
    end    
  end
end
end
end