
# Should be included via extend
#
# extend Mixins::ObjectInterface
#

module Coral
module Mixins
module ObjectInterface
  
  include SubConfig

  #-----------------------------------------------------------------------------
  # Object collections
  
  def object_collection(type, plural, ensure_proc, delete_proc = nil, search_proc = nil)
    
    define_method "#{type}_info" do |name = nil|
      ( name ? get([ plural, name ], {}) : get(plural, {}) )
    end
  
    #---
    
    define_method "#{type}_setting" do |name, property, default = nil, format = false|
      get([ plural, name, property ], default, format)
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
        obj = ensure_proc.call(name, info)
        _set([ type, name ], obj)
      end
    end
  
    #---

    define_method "set_#{plural}" do |data = {}|
      data = symbol_map(hash(data))
    
      send("clear_#{plural}")
      set(plural, data)
    
      data.each do |name, info|
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
      set([ plural, name ], info)
    
      obj = ensure_proc.call(name, symbol_map(info)) 
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
  
  def plugin_collection(type, plural, ensure_proc, search_proc = nil)
    object_collection(type, plural, ensure_proc,
      Proc.new { |plugin| Coral.remove_plugin(plugin) },
      search_proc
    )    
  end
end
end
end