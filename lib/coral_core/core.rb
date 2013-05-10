
module Coral
class Core
  
  #-----------------------------------------------------------------------------
  # Properties
  
  @@ui = Interface.new("coral")
  
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    config = Config.ensure(options)
    
    @@ui = Interface.new(config)
  end
  
  #-----------------------------------------------------------------------------
  # Accessor / Modifiers
  
  attr_accessor :ui
  
  #-----------------------------------------------------------------------------
  
  def self.ui
    return @@ui
  end
  
  #---
  
  def self.logger
    return @@ui.logger
  end
  
  #--- 
   
  def logger
    return self.class.logger
  end
  
  #---
 
  def logger=logger
    self.class.logger = logger
  end
 
  #-----------------------------------------------------------------------------
  # General utilities

  def self.symbol_map(data)
    results = {}
    return data unless data
    
    case data
    when Hash
      data.each do |key, value|
        results[key.to_sym] = symbol_map(value)
      end
    else
      results = data
    end    
    return results
  end
  
  #---
  
  def symbol_map(data)
    return self.class.symbol_map(data)
  end
  
  #---
  
  def self.string_map(data)
    results = {}
    return data unless data
    
    case data
    when Hash
      data.each do |key, value|
        results[key.to_s] = string_map(value)
      end
    else
      results = data
    end    
    return results
  end
  
  #---
  
  def string_map(data)
    return self.class.string_map(data)
  end
  
  #-----------------------------------------------------------------------------
      
  def self.filter(data, method = false)
    if method && method.is_a?(Symbol) && 
      [ :array, :hash, :string, :symbol, :test ].include?(method.to_sym)
      return send(method, data)
    end
    return data
  end
  
  #---
  
  def filter(data, method = false)
    return self.class.filter(data, method)
  end
    
  #-----------------------------------------------------------------------------
          
  def self.array(data, default = [], split_string = false)
    result = default    
    if data
      case data
      when Array
        result = data
      when String
        result = [ ( split_string ? data.split(/\s*,\s*/) : data ) ]
      else
        result = [ data ]
      end
    end
    return result
  end
  
  #---
  
  def array(data, default = [], split_string = false)
    return self.class.array(data, default, split_string)
  end
    
  #---
        
  def self.hash(data, default = {})
    result = default    
    if data
      case data
      when Hash
        result = data
      else
        result = {}
      end
    end
    return result
  end
  
  #---
  
  def hash(data, default = {})
    return self.class.hash(data, default)
  end
    
  #---
         
  def self.string(data, default = '')
    result = default    
    if data
      case data
      when String
        result = data
      else
        result = data.to_s
      end
    end
    return result
  end
  
  #---
  
  def string(data, default = '')
    return self.class.string(data, default)
  end
    
  #---
         
  def self.symbol(data, default = :undefined)
    result = default    
    if data
      case data
      when Symbol
        result = data
      when String
        result = data.to_sym
      else
        result = data.class.to_sym
      end
    end
    return result
  end
  
  #---
  
  def symbol(data, default = '')
    return self.class.symbol(data, default)
  end
     
  #---
    
  def self.test(data)
    return false if Util::Data.empty?(data)
    return true
  end
  
  #---
  
  def test(data)
    return self.class.test(data)
  end  
end
end