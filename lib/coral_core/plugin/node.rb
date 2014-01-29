
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
 
  #---
  
  def network=network
    self.plugin_parent = network
  end
  
  #---
  
  def setting(property, default = nil, format = false)
    return network.node_setting(plugin_provider, name, property, default, format)
  end
  
  #---
  
  def search(property, default = nil, format = false)
    return network.search_node(plugin_provider, name, property, default, format)
  end
  
  #---
  
  def set_setting(property, value = nil)
    network.set_node_setting(plugin_provider, name, property, value)
    return self
  end
  
  #---
  
  def delete_setting(property)
    network.delete_node_setting(plugin_provider, name, property)
    return self
  end
  
  #-----------------------------------------------------------------------------
  
  def machine
    return get(:machine, nil)
  end
  
  #---
  
  def machine=machine
    set(:machine, machine)  
  end
  
  #---
 
  def create_machine(provider, options = {})
    if provider.is_a?(String) || provider.is_a?(Symbol)
      set(:machine, Coral.machine(options, provider))
    end
    return self
  end
 
  #---
  
  def public_ip # Must be set at machine level
    return machine.public_ip if machine
    return nil
  end

  #---
  
  def private_ip # Must be set at machine level
    return machine.private_ip if machine
    return nil
  end

  #---
 
  def hostname # Must be set at machine level
    return machine.hostname if machine
    return ''
  end
 
  #---
 
  def state # Must be set at machine level
    return machine.state if machine
    return nil
  end
 
  #-----------------------------------------------------------------------------
  # Machine operations
    
  def start(options = {})
    return true unless machine
    return machine.start(options)
  end
  
  #---
    
  def stop(options = {})
    return true unless machine && machine.running?    
    return machine.stop(options)
  end

  #---
    
  def reload(options = {})
    return true unless machine && machine.created?    
    return machine.reload(options)
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
    return true    
  end

  #---
  
  def exec(commands, options = {})
    return true unless machine && machine.running?
    
    config = Config.ensure(options)        
    return machine.exec(config.import({ :commands => commands }))  
  end
   
  #---
  
  def provision(options = {})
    return true unless machine && machine.running?    
    return machine.provision(options)  
  end
 
  #---
  
  def create_image(options = {})
    return true unless machine && machine.running?    
    return machine.create_image(options)  
  end
 
  #-----------------------------------------------------------------------------
  # Utilities
  
  def self.build_info(type, data)  
    data = data.split(/\s*,\s*/) if data.is_a?(String)
    return super(type, data)
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
    return options
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
    return nil
  end
  
  #---
  
  def translate_reference(reference)
    return self.class.translate_reference(reference)
  end             
end
end
end
