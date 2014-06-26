
module CORL
module Mixin
module Builder
module Global # Extend
  
  #-----------------------------------------------------------------------------
  # Accessors / modifiers
  
  def resource_joiner
    '::'
  end
  
  #---
  
  def id_joiner
    '__'
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def id(name = nil)
    name = 'unknown' if name.nil?
    name       = [ name ] unless name.is_a?(Array)
    components = []
    
    name.flatten.each do |component|
      components << component.to_s.gsub(resource_joiner, id_joiner)
    end
    components.join(id_joiner).to_sym
  end
  
  #---
  
  def resource(name = nil, capitalize = false)
    name = 'unknown' if name.nil?
    concatenate(name, capitalize, resource_joiner)
  end
  
  #---
  
  def concatenate(components, capitalize = false, joiner = nil)
    joiner = resource_joiner unless joiner
    
    if components.is_a?(Array)
      components = components.collect do |str|
        str.to_s.split(id_joiner)  
      end.flatten
    else
      components = [ components.to_s.split(id_joiner) ].flatten
    end
    
    if capitalize
      name = components.collect {|str| str.capitalize }.join(joiner)
    else
      name = components.join(joiner)
    end
    name
  end
  
  #---
  
  def process_environment(settings, environment = nil)
    config      = Config.new(hash(settings))
    env_config  = config.delete(:environment)
    environment = environment.to_sym if environment
    
    if env_config    
      if environment && env_config.has_key?(environment)
        local_env_config = env_config[environment]
        
        while local_env_config && local_env_config.has_key?(:use) do
          local_env_config = env_config[local_env_config[:use].to_sym]
        end
         
        config.defaults(local_env_config) if local_env_config
      end
      config.defaults(env_config[:default]) if env_config.has_key?(:default)
    end
    config.export 
  end
end

#-------------------------------------------------------------------------------

module Instance # Include
  
  extend Global
    
  #-----------------------------------------------------------------------------
  # Accessors / modifiers
  
  def resource_joiner
    self.class.resource_joiner
  end
  
  #---
  
  def id_joiner
    self.class.id_joiner
  end
  
  #---
  
  def build_directory
    network.build_directory
  end
  
  #---
  
  def build_config
    return network.build if network
    nil
  end
 
  #---
  
  def build_lock
    self.class.build_lock
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def id(name = nil)
    name = plugin_name if name.nil?
    self.class.id(name)
  end
  
  #---
  
  def resource(name = nil, capitalize = false)
    name = plugin_name if name.nil?
    self.class.resource(name, capitalize)
  end
  
  #---
  
  def concatenate(components, capitalize = false, joiner = nil)
    self.class.concatenate(components, capitalize, joiner)
  end
  
  #---
  
  def internal_path(directory)
    directory.gsub(network.directory + "/", '')
  end
  
  #---
  
  def process_environment(settings, environment = nil)
    self.class.process_environment(settings, environment)
  end  
end
end
end
end
