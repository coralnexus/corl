
module Coral
    
  #-----------------------------------------------------------------------------
  # Core plugin type facade
  
  def self.extension(provider)
    return plugin(:extension, provider, {})
  end
  
  #---
  
  def self.configuration(options, provider = nil)
    return plugin(:configuration, provider, options)
  end
  
  def self.configurations(data, build_hash = false, keep_array = false)
    return plugins(:configuration, data, build_hash, keep_array)
  end
  
  #---
  
  def self.action(provider, args = [], quiet = false)
    return plugin(:action, provider, { :args => args, :quiet => quiet })
  end
  
  def self.actions(data, build_hash = false, keep_array = false)
    return plugins(:action, data, build_hash, keep_array)  
  end
  
  #---
  
  def self.project(options, provider = nil)
    return plugin(:project, provider, options)
  end
  
  def self.projects(data, build_hash = false, keep_array = false)
    return plugins(:project, data, build_hash, keep_array)
  end
   
  #-----------------------------------------------------------------------------
  # Cluster plugin type facade
   
  def self.network(name, options = {}, provider = nil)
    return plugin(:network, provider, Config.ensure(options).import({ :name => name }))
  end
  
  def self.networks(data, build_hash = false, keep_array = false)
    return plugins(:network, data, build_hash, keep_array)
  end
   
  #---
  
  def self.node(name, options = {}, provider = nil)
    return plugin(:node, provider, Config.ensure(options).import({ :name => name }))
  end
  
  def self.nodes(data, build_hash = false, keep_array = false)
    return plugins(:node, data, build_hash, keep_array)
  end
   
  #---
  
  def self.machine(options = {}, provider = nil)
    return plugin(:machine, provider, options)
  end
  
  def self.machines(data, build_hash = false, keep_array = false)
    return plugins(:machine, data, build_hash, keep_array)
  end
  
  #---
  
  def self.provisioner(options, provider = nil)
    return plugin(:provisioner, provider, options)
  end
  
  #---
  
  def self.provisioners(data, build_hash = false, keep_array = false)
    return plugins(:provisioner, data, build_hash, keep_array)
  end
  
  #---
  
  def self.command(options, provider = nil)
    return plugin(:command, provider, options)
  end
  
  def self.commands(data, build_hash = false, keep_array = false)
    return plugins(:command, data, build_hash, keep_array)
  end
    
  #-----------------------------------------------------------------------------
  # Utility plugin type facade
  
  def self.event(options, provider = nil)
    return plugin(:event, provider, options)
  end
  
  def self.events(data, build_hash = false, keep_array = false)
    return plugins(:event, data, build_hash, keep_array)
  end
  
  #---
  
  def self.template(options, provider = nil)
    return plugin(:template, provider, options)
  end
  
  def self.templates(data, build_hash = false, keep_array = false)
    return plugins(:template, data, build_hash, keep_array)
  end
   
  #---
  
  def self.translator(options, provider = nil)
    return plugin(:translator, provider, options)
  end
  
  def self.translators(data, build_hash = false, keep_array = false)
    return plugins(:translator, data, build_hash, keep_array)
  end
end
