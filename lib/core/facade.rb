
module CORL
module Facade
  
  extend Nucleon::Facade
  
  def self.included(klass)
    klass.send(:extend, Nucleon::Facade)
  end
    
  #-----------------------------------------------------------------------------
  # Core plugin type facade
  
  def configuration(options, provider = nil)
    plugin(:configuration, provider, options)
  end
  
  def configurations(data, build_hash = false, keep_array = false)
    plugins(:configuration, data, build_hash, keep_array)
  end
  
  #-----------------------------------------------------------------------------
  # Cluster plugin type facade
   
  def network(name, options = {}, provider = nil)
    plugin(:network, provider, Config.ensure(options).import({ :name => name }))
  end
  
  def networks(data, build_hash = false, keep_array = false)
    plugins(:network, data, build_hash, keep_array)
  end
   
  #---
  
  def node(name, options = {}, provider = nil)
    plugin(:node, provider, Config.ensure(options).import({ :name => name }))
  end
  
  def nodes(data, build_hash = false, keep_array = false)
    plugins(:node, data, build_hash, keep_array)
  end
  
  #---
  
  def provisioner(options, provider = nil)
    plugin(:provisioner, provider, options)
  end
  
  #---
  
  def provisioners(data, build_hash = false, keep_array = false)
    plugins(:provisioner, data, build_hash, keep_array)
  end
end
end
