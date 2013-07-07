
module Coral
module Mixins
module SubConfig
  
  #-----------------------------------------------------------------------------
  # Propety accessors / modifiers
  
  def name
    return _get(:name)
  end
  
  #---
  
  def name=name
    _set(:name, string(name))
  end
  
  #---
    
  def config(default = nil)
    return _get(:config, default)
  end
  
  #---
  
  def config=config
    _set(:config, config)
  end
    
  #-----------------------------------------------------------------------------
  
  def _parent_exec(method, *params)
    return self.class.superclass.instance_method(method).bind(self).call(*params)
  end
  protected :_parent_exec
  
  #---
  
  def _get(keys, default = nil, format = false)
    return _parent_exec(:get, keys, default, format)  
  end
  protected :_get
  
  #---
  
  def get(keys, default = nil, format = false)
    return config.get(keys, default, format)
  end
  
  #---
  
  def _init(keys, default = nil)
    return _set(keys, _get(keys, default))
  end
  protected :_init

  #---
 
  def _set(keys, value = '', options = {})
    return _parent_exec(:set, keys, value, options)  
  end
  protected :_set
  
  #---
    
  def set(keys, value = '', options = {})
    config.set(keys, value, options)
    return self
  end
  
  #---
 
  def _delete(keys, options = {})
    return _parent_exec(:delete, keys, options)  
  end
  protected :_delete
  
  #---
   
  def delete(keys, options = {})
    config.delete(keys, options)
    return self
  end
 
  #---
 
  def _clear(options = {})
    return _parent_exec(:clear, options)  
  end
  protected :_clear
  
  #---
  
  def clear(options = {})
    config.clear(options)
    return self
  end
  
  #-----------------------------------------------------------------------------
  # Import / Export
  
  def _import(properties, options = {})
    return _parent_exec(:import, properties, options)
  end
  protected :_import
  
  #---
  
  def import(properties, options = {})
    config.import(properties, options)
    return self
  end
  
  #---
  
  def _export
    return _parent_exec(:export)
  end
  protected :_export
  
  #---
  
  def export
    return config.export
  end
end
end
end