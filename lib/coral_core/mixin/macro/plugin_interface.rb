
# Should be included via extend
#
# extend Mixin::Macro::PluginInterface
#

coral_require(File.dirname(__FILE__), :object_interface)

#---

module Coral
module Mixin
module Macro
module PluginInterface
  
  include Mixin::Macro::ObjectInterface
  
  #-----------------------------------------------------------------------------
  # Plugin collections
  
  def plugin_collection(_type, _method_options = {})
    _method_config = Config.ensure(_method_options)
    _method_config.set(:plugin, true)
    
    _plural          = _method_config.init(:plural, "#{_type}s").get(:plural)
    _search_proc     = _method_config.get(:search_proc)
    _single_instance = _method_config.get(:single_instance, false)
    _plugin_type     = _method_config.get(:plugin_type, _type)
    
    @@object_types[_type] = _method_config
    
    #---------------------------------------------------------------------------
    
    object_utilities
      
    #---
    
    unless respond_to? :each_plugin!
      define_method :each_plugin! do |plugin_types = nil, providers = nil|
        providers = [ providers ] if providers && ! providers.is_a?(Array)
        
        filter_proc = Proc.new {|type, config| config[:plugin] }
        each_object_type!(plugin_types, filter_proc) do |type, plural, options|
          send(plural).each do |provider, plugins|
            unless providers && ! providers.include?(provider)
              if plugins.is_a?(Hash)
                plugins.each do |name, plugin|
                  yield(type, provider, plugin)  
                end
              else
                yield(type, provider, plugin)
              end
            end
          end 
        end  
      end
    end
    
    #---
    
    define_method "each_#{_type}!" do |providers = nil|
      each_plugin!(_type, providers) do |type, provider, plugin|
        yield(type, provider, plugin)    
      end
    end
    
    #---------------------------------------------------------------------------
    
    if _single_instance
      define_method "#{_type}_config" do |provider|
        Config.new(get([ _type, provider ], {}))
      end
      
      #---
      
      define_method "#{_type}_setting" do |provider, property, default = nil, format = false|
        get([ _type, provider, property ], default, format)
      end
      
    #---------------------------------------------------------------------------  
    else
      define_method "#{_type}_config" do |provider, name = nil|
        Config.new( name ? get([ _plural, provider, name ], {}) : get(_plural, provider, {}) )
      end
      
      #---
      
      define_method "#{_type}_setting" do |provider, name, property, default = nil, format = false|
        get([ _plural, provider, name, property ], default, format)
      end
    end
   
    #---------------------------------------------------------------------------
    
    define_method "#{_plural}" do |provider = nil|
      ( provider ? _get([ _plural, provider ], {}) : _get(_plural, {}) )
    end
    
    #---
  
    define_method "init_#{_plural}" do |providers = nil|
      data = hash(_search_proc.call) if _search_proc
      data = get_hash(_plural) unless data
      
      providers = [ providers ] if providers && ! providers.is_a?(Array)
      
      symbol_map(data).each do |provider, instance_settings|
        if ! providers || providers.include?(provider)
          if _single_instance
            plugin = Coral.plugin(_plugin_type, provider, instance_settings)
            plugin.plugin_parent = self
          
            _set([ _plural, provider ], plugin)
          else
            instance_settings.each do |name, options|
              if name != :settings
                options[:name] = name
                plugin         = Coral.plugin(_plugin_type, provider, options)
                plugin.plugin_parent = self
          
                _set([ _plural, provider, name ], plugin)
              end
            end
          end
        end
      end
    end
  
    #---

    define_method "set_#{_plural}" do |data = {}|
      data = Config.ensure(data).export
    
      send("clear_#{_plural}")
      set(_plural, data)
    
      data.each do |provider, instance_settings|
        if _single_instance
          plugin = Coral.plugin(_plugin_type, provider, instance_settings)              
          plugin.plugin_parent = self
          
          _set([ _plural, provider ], plugin)  
        else
          instance_settings.each do |name, options|
            options[:name] = name
            plugin         = Coral.plugin(_plugin_type, provider, options)
            plugin.plugin_parent = self
        
            _set([ _plural, provider, name ], plugin)  
          end
        end
      end
      self
    end
    
    #---
    
    define_method "clear_#{_plural}" do
      _get(_plural).keys.each do |name|
        send("delete_#{_type}", name)
      end
      self
    end

    #---------------------------------------------------------------------------
    
    if _single_instance
      define_method "#{_type}" do |provider|
        _get([ _plural, provider ])
      end
      
      #---
      
      define_method "set_#{_type}" do |provider, options = {}|
        options = Config.ensure(options).export
      
        set([ _plural, provider ], options)
    
        plugin = Coral.plugin(_plugin_type, provider, options)
        plugin.plugin_parent = self
        
        _set([ _plural, provider ], plugin)
        self
      end
          
      #---

      define_method "set_#{_type}_setting" do |provider, property, value = nil|
        set([ _plural, provider, property ], value)
        self
      end
    
      #---

      define_method "delete_#{_type}" do |provider|
        plugin = send(_type, provider)
    
        delete([ _plural, provider ])
        _delete([ _plural, provider ])
    
        Coral.remove_plugin(plugin)
        self
      end
  
      #---
  
      define_method "delete_#{_type}_setting" do |provider, property|
        delete([ _plural, provider, property ])
        self
      end
      
      #---
      
      define_method "search_#{_type}" do |provider, keys, default = '', format = false|
        plugin_config = send("#{_type}_config", provider)
        search_object(plugin_config, keys, default, format)      
      end
      
    #---------------------------------------------------------------------------
    else
      define_method "#{_type}" do |provider, name|
        _get([ _plural, provider, name ])
      end
      
      #---
      
      define_method "set_#{_type}" do |provider, name, options = {}|
        options = Config.ensure(options).export
      
        set([ _plural, provider, name ], options)
    
        options[:name] = name
        plugin         = Coral.plugin(_plugin_type, provider, options)
        plugin.plugin_parent = self
        
        _set([ _plural, provider, name ], plugin)
        self
      end
          
      #---

      define_method "set_#{_type}_setting" do |provider, name, property, value = nil|
        set([ _plural, provider, name, property ], value)
        self
      end
    
      #---

      define_method "delete_#{_type}" do |provider, name|
        plugin = send(_type, provider, name)
    
        delete([ _plural, provider, name ])
        _delete([ _plural, provider, name ])
    
        Coral.remove_plugin(plugin)
        self
      end
  
      #---
  
      define_method "delete_#{_type}_setting" do |provider, name, property|
        delete([ _plural, provider, name, property ])
        self
      end
      
      #---
      
      define_method "search_#{_type}" do |provider, name, keys, default = '', format = false|
        plugin_config = send("#{_type}_config", provider, name)
        search_object(plugin_config, keys, default, format)      
      end
    end  
  end
end
end
end
end
