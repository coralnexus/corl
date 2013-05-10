
module Coral
class Event < Core
 
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def self.instance!(data = {}, build_hash = false, keep_array = false)
    group  = ( build_hash ? {} : [] )    
    events = build_info(data)
    
    index = 1
    events.each do |info|
      type = info[:type]
      
      if type && ! type.empty?
        event = ( block_given? ? yield(type, info) : create(type, info) )
                
        if event
          if build_hash
            group[index] = event
          else
            group << event
          end
        end
      end
      index += 1
    end
    if ! build_hash && events.length == 1 && ! keep_array
      return group.shift
    end
    return group
  end
  
  #---
  
  def self.instance(options = {}, build_hash = false, keep_array = false)
    return instance!(options, build_hash, keep_array)
  end
  
  #---
  
  def initialize(options = {})
    config = Config.ensure(options)
    
    super(config)
    
    @name       = config.get(:name, '')
    @delegate   = config.get(:delegate, nil)  
    @properties = config.options
  end
    
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  attr_accessor :name

  #---
  
  def type
    return string(@properties[:type])
  end
  
  #---
  
  def set_properties(data)
    return @delegate.set_properties(data) if @delegate
    
    @properties = hash(data)
    return self
  end
   
  #---
 
  def property(name, default = '', format = false)
    name = name.to_sym
    
    property = default
    property = filter(@properties[name], format) if @properties.has_key?(name)
    return property  
  end
 
  #---
  
  def set_property(name, value)
    return @delegate.set_property(name, value) if @delegate
    
    @properties[name] = value
    return self
  end
     
  #-----------------------------------------------------------------------------
  # Import / Export
  
  def export
    return type
  end
      
  #-----------------------------------------------------------------------------
  # Event handling
   
  def check(source)
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info!(data = {})  
    events = []
    
    if data.is_a?(String)
      data = data.split(/\s*,\s*/)
    elsif data.is_a?(Hash)
      data = [ data ]
    end
    
    if data.is_a?(Array)
      data.each do |element|
        event = {}
        
        if block_given?
          event = yield(element)
        else
          case element        
          when String
            event = split_event_string(element)
                
          when Hash          
            event = element
          end
        end
        
        unless event.empty?
          events << event
        end
      end
    end
    return events
  end
  
  #---
  
  def self.build_info(data = {})
    return build_info!(data)
  end
  
  #-----------------------------------------------------------------------------
  
  def self.create(type, info)
    event = nil
    begin
      event = Module.const_get("Coral").const_get("#{type.capitalize}Event").new(info)
    rescue
    end
    return event
  end
  
  #-----------------------------------------------------------------------------
  
  def self.split_event_string(data)
    info          = {}    
    components    = data.split(':')
    info[:type]   = components.shift
    info[:string] = components.join(':')
    
    return info
  end
end
end