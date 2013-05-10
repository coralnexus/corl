
require 'json'

module Coral
class Memory < Repository
   
  #-----------------------------------------------------------------------------
  # Constructor / Destructor
  
  def initialize(options = {})
    config = Config.ensure(options)
    
    super(config)
    
    @absolute_config_file = ''
    
    @properties     = config.get(:properties, {})
    
    @autoload       = config.get(:autoload, true)
    @autosave       = config.get(:autosave, true)
    @autocommit     = config.get(:autocommit, true)
    @commit_message = config.get(:commit_message, 'Saving state')
    
    self.config_file = config.get(:config_file, '')
    dbg(self, 'memory')
  end
  
  #---
  
  def self.finalize(file_name)
    proc do
      Coral::Util::Disk.close(file_name)
    end
  end
    
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  attr_accessor :autoload, :autosave, :autocommit, :commit_message
  attr_reader :config_file, :absolute_config_file

  #---
 
  def set_absolute_config_file
    if @directory.empty? || @config_file.empty?
      @absolute_config_file = ''
    else 
      @absolute_config_file = ( ! @submodule.empty? ? File.join(@directory, @submodule, @config_file) : File.join(@directory, @config_file) )
      ObjectSpace.define_finalizer(self, self.class.finalize(@absolute_config_file))
    end
    return self
  end
 
  #---
  
  def config_file=config_file
    unless Util::Data.empty?(config_file)
      @config_file = ( config_file.is_a?(Array) ? config_file.join(File::SEPARATOR) : string(config_file) )
    end
    
    set_absolute_config_file
    load if @autoload
  end
  
  #-----------------------------------------------------------------------------
 
  def get(key, default = '', format = false)
    value = default
    key   = string(key)
          
    if ! @properties || ! @properties.is_a?(Hash)
      @properties = {}
    end
    if @properties.has_key?(key)
      value = @properties[key]
    end     
    return filter(value, format)
  end
    
  #---
   
  def set(key, value = '')
    key = string(key)
       
    if ! @properties || ! @properties.is_a?(Hash)
      @properties = {}
    end
    @properties[key] = value
    save if @autosave
    return self
  end
    
  #---
   
  def delete(key)
    key = string(key)
        
    if ! @properties || ! @properties.is_a?(Hash)
      @properties = {}
    end
    @properties.delete(key)
    save if @autosave
    return self
  end
    
  #---
    
  def get_group(group, name = '', key = nil, default = {}, format = false)
    info  = get(group, {})
    value = info
    
    if name
      name = string(name)
      if info.has_key?(name) && info[name].is_a?(Hash)
        if key && ! key.empty?
          key = string(key)
          if info[name].has_key?(key)
            value = info[name][key]
          else
            value = default
          end
        else
          value = info[name]
        end          
      else
        value = default     
      end        
    end
    return filter(value, format)
  end
       
  #---
    
  def set_group(group, name, key = nil, value = {})
    group = string(group)
    name  = string(name)
    
    if ! @properties || ! @properties.is_a?(Hash)
      @properties = {}
    end
    if ! @properties[group] || ! @properties[group].is_a?(Hash)
      @properties[group] = {}
    end      
      
    if key && ! key.empty?
      key = string(key)
      if ! @properties[group][name] || ! @properties[group][name].is_a?(Hash)
        @properties[group][name] = {}  
      end
      @properties[group][name][key] = value
        
    else
      @properties[group][name] = value  
    end
    save if @autosave
    return self
  end
       
  #---
    
  def delete_group(group, name, key = nil)
    group = string(group)
    name  = string(name)
    
    if ! @properties || ! @properties.is_a?(Hash)
      @properties = {}
    end
    if ! @properties[group] || ! @properties[group].is_a?(Hash)
      @properties[group] = {}
    end      
      
    if key && ! key.empty?
      key = string(key)
      if @properties[group][name] && @properties[group][name].is_a?(Hash)
        @properties[group][name].delete(key)
      end
    else
      @properties[group].delete(name)  
    end
    save if @autosave
    return self
  end
  
  #-----------------------------------------------------------------------------
  # Import / Export
  
  def export
    return @properties
  end
       
  #-----------------------------------------------------------------------------
  # Configuration loading / saving
    
  def load
    if can_persist?
      config = Coral::Util::Disk.read(@absolute_config_file)    
      if config && ! config.empty?
        @properties = JSON.parse(config)
      end
    end
    return self
  end
    
  #---
    
  def save(options = {})
    if can_persist?
      config = JSON.generate(@properties)
      if config && ! config.empty?
        Coral::Util::Disk.write(@absolute_config_file, config)
        commit(@absolute_config_file, options) if @autocommit
      end
    end
    return self
  end  
     
  #-----------------------------------------------------------------------------
  # Checks
  
  def can_persist?
    success = super
    success = false if success && @absolute_config_file.empty?
    return success
  end
end
end