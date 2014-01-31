
module Coral
module Plugin
class Node < Base
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize
    super
  end
       
  #-----------------------------------------------------------------------------
  # Checks
    
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def network
    return plugin_parent
  end
 
  def network=network
    self.plugin_parent = network
  end
  
  #---
  
  def setting(property, default = nil, format = false)
    return network.node_setting(plugin_provider, name, property, default, format)
  end
  
  def search(property, default = nil, format = false)
    return network.search_node(plugin_provider, name, property, default, format)
  end
  
  def set_setting(property, value = nil)
    network.set_node_setting(plugin_provider, name, property, value)
    return self
  end
  
  def delete_setting(property)
    network.delete_node_setting(plugin_provider, name, property)
    return self
  end
  
  #-----------------------------------------------------------------------------
  
  def groups
    search(:groups, [], :array)
  end
  
  #-----------------------------------------------------------------------------
  
  def machine
    @machine
  end
  
  #---
  
  def machine=machine
    @machine = machine  
  end
  
  #---
 
  def create_machine(provider, options = {})
    if provider.is_a?(String) || provider.is_a?(Symbol)
      self.machine = Coral.machine(options, provider)
    end
    self
  end
 
  #---
  
  def public_ip # Must be set at machine level
    return machine.public_ip if machine
    nil
  end

  #---
  
  def private_ip # Must be set at machine level
    return machine.private_ip if machine
    nil
  end

  #---
 
  def hostname # Must be set at machine level
    return machine.hostname if machine
    ''
  end
 
  #---
 
  def state # Must be set at machine level
    return machine.state if machine
    nil
  end
 
  #-----------------------------------------------------------------------------
  # Machine operations
    
  def start(options = {})
    return true unless machine
    machine.start(options)
  end
  
  #---
    
  def stop(options = {})
    return true unless machine && machine.running?    
    machine.stop(options)
  end

  #---
    
  def reload(options = {})
    return true unless machine && machine.created?    
    machine.reload(options)
  end
    
  #---

  def destroy(options = {})    
    return true unless machine
    
    config = Config.ensure(options)
    
    if machine.created?
      run = false

      if config[:force]
        run = true
      else
        choice = nil
        begin
          choice = ui.ask("Are you sure you want to remove: #{name}?")
          run    = choice.upcase == "Y"
        rescue Errors::UIExpectsTTY
          run = false
        end        
      end

      if run
        return machine.destroy(config)
      end
    end
    true    
  end

  #---
  
  def exec(commands, options = {})
    return true unless machine && machine.running?
    
    config = Config.ensure(options)        
    machine.exec(config.import({ :commands => commands }))  
  end
   
  #---
  
  def provision(options = {})
    return true unless machine && machine.running?    
    machine.provision(options)  
  end
 
  #---
  
  def create_image(options = {})
    return true unless machine && machine.running?    
    machine.create_image(options)  
  end
 
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info(type, data)  
    data = data.split(/\s*,\s*/) if data.is_a?(String)
    super(type, data)
  end
  
  #---
   
  def self.translate(data)
    options = super(data)
    
    case data        
    when String
      options = { :name => data }
    when Hash
      options = data
    end
    
    if options.has_key?(:name)
      if matches = translate_reference(options[:name])
        options[:provider] = matches[:provider]
        options[:name]     = matches[:name]
        
        logger.debug("Translating node options: #{options.inspect}")  
      end
    end
    options
  end
  
  #---
  
  def self.translate_reference(reference)
    # ex: rackspace:::web1.staging.example.com
    if reference && reference.match(/^\s*([a-zA-Z0-9_-]+):::([^\s]+)\s*$/)
      provider = $1
      name     = $2
      
      logger.debug("Translating node reference: #{provider}  #{name}")
      
      info = {
        :provider => provider,
        :name     => name
      }
      
      logger.debug("Project reference info: #{info.inspect}")
      return info
    end
    nil
  end
  
  #---
  
  def translate_reference(reference)
    self.class.translate_reference(reference)
  end             
end
end
end
