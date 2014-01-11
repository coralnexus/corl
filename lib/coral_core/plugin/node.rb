
module Coral
module Plugin
class Node < Base
 
  #-----------------------------------------------------------------------------
  # Cloud plugin interface
   
  def normalize
    super
    
    unless get(:cloud)
      set(:cloud, Coral.cloud(name))
    end   
     
    self.machine = get(:machine, 'default')
   
    init_projects
    init_shares
  end
       
  #-----------------------------------------------------------------------------
  # Checks
    
   
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def setting(property, default = nil, format = false)
    return cloud.node_setting(name, property, default, format)
  end
  
  #---
  
  def search(property, default = nil, format = false)
    return cloud.search(name, property, default, format)
  end
  
  #---
  
  def set_setting(property, value = nil)
    cloud.set_node_setting(name, property, value)
    return self
  end
  
  #---
  
  def delete_setting(property)
    cloud.delete_node_setting(name, property)
    return self
  end
  
  #-----------------------------------------------------------------------------
  
  def cloud
    return plugin_parent
  end
 
  #---
  
  def cloud=cloud
    self.plugin_parent = (cloud.is_a?(Coral::Plugin::Cloud) ? cloud : Coral.cloud(name) )
    
    init_shares
  end
  
  #---
  
  def machine(default = nil)
    return get(:machine, default)
  end
  
  #---
 
  def machine=machine
    set(:name, '')
    
    if machine.is_a?(String) || machine.is_a?(Symbol)
      set(:machine, nil)
      set(:name, machine)
    else
      set(:machine, machine)
      set(:name, machine.name.to_s) if machine
    end
  end
  
  #---
  
  def hostname # Must be set at machine level
    return machine.hostname if machine
    return nil
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
  
  def virtual_hostname
    return search(:virtual_hostname, '', :string)
  end
  
  #---
  
  def virtual_ip
    return search(:virtual_ip, '', :string)
  end
  
  #-----------------------------------------------------------------------------
  # Plugin collections

  def plugins!(plural, reset = false)
    plugins = get(plural, {}, :hash)
    
    return plugins unless plugins.empty? || reset
    
    plugins = {}
    hash(yield(type, plural)).each do |provider, names|
      names = [ names ] unless names.is_a?(Array)
      
      plugins[provider] = {} unless plugins.has_key?(provider)
     
      names.each do |name|
        plugins[provider][name] = cloud.send(provider, name)
      end     
    end
    set(plural, plugins)
  end
      
  #-----------------------------------------------------------------------------
  # Shares

  def shares(reset = false)
    return plugins!(:share, :shares, reset) do |type, plural|
      search(plural, {}, :hash)  
    end
  end

  #-----------------------------------------------------------------------------
  # Machine operations
    
  def start(options = {})
    sync_projects(options)
    
    return true unless machine    
    return machine.start(options)
  end
  
  #---
    
  def stop(options = {})
    sync_projects(options)
        
    return true unless machine    
    return machine.stop(options)
  end
     
  #---
  
  def update(options = {})
    sync_projects(options)
    
    success = true    
    return success unless machine    
    
    if machine.running?
      success = Command.new("vagrant provision #{name}").exec!(options) do |line|
        process_puppet_message(line)
      end    
    end
    return success   
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
 
  #-----------------------------------------------------------------------------
  # Utilities
  
  def process_puppet_message(line)
    return line.match(/(err|error):\s+/i) ? { :success => false, :prefix => 'FAIL' } : true
  end              
end
end
end
