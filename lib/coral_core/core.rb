
require "log4r"

module Coral
class Core

  #-----------------------------------------------------------------------------
  # Properties
    
  @@logger = Log4r::Logger.new("coral::core")
 
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    class_name = self.class.to_s.downcase
    
    # Logger setup
    if options.has_key?(:logger)
      if options[:logger].is_a?(String)
        @logger = Log4r::Logger.new(options[:logger])
      else
        @logger = options[:logger] 
      end
    else
      @logger = Log4r::Logger.new("coral::#{class_name}")
    end
    
    # UI setup
    if options.has_key?(:ui)
      if options[:ui].is_a?(String)
        @ui = Coral::UI::Color.new(options[:ui])
      else
        @ui = options[:ui] 
      end
    else
      @ui = Coral::UI::Color.new(class_name)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Accessor / Modifiers
  
  attr_accessor :logger, :ui
  
  #---
  
  def self.logger
    return @@logger
  end
  
  #---  
    
  def self.logger=logger
    @@logger = logger
  end
  
  #---
  
  def self.ui
    return @@ui
  end
  
  #---
  
  def self.ui=ui
    @@ui = ui
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
    if data && ! data.empty?
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
    if data && ! data.empty?
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
    if data && ! data.empty?
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
    if data && ! data.empty?
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
    return false if ! data || data.empty?      
    return false if data.is_a?(String) && data =~ /^(FALSE|false|False|No|no|N|n)$/      
    return true
  end
  
  #---
  
  def test(data)
    return self.class.test(data)
  end  
end
end