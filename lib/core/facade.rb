
module CORL
module Facade

  #-----------------------------------------------------------------------------
  # Facter lookup
  
  @@facts = {}
  
  def facts(reset = false)
    if reset || @@facts.empty?
      @@facts = {} if reset
      silence do
        Facter.list.each do |name|
          @@facts[name] = Facter.value(name)
        end
      end
    end
    @@facts
  end
  
  #---
  
  def create_fact(name, value, weight = 1000)
    Facter.collection.add(name.to_sym, { 
      :value  => value, 
      :weight => weight 
    })
  end
  
  #---
  
  def fact(name)
    silence do
      Facter.value(name)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Local identification
  
  def public_ip
    if Config.fact(:vagrant_exists)
      Config.fact(:ipaddress_eth1)  
    else
      CORL.ip_address  
    end
  end
  
  #-----------------------------------------------------------------------------
  # Vagrant related
  
  def vagrant?
    Vagrant.command ? true : false
  end
  
  #---
  
  @@vagrant_config_loaded = false
  
  def vagrant_config_loaded?
    @@vagrant_config_loaded
  end
  
  def vagrant_config(directory, config, &code)
    Vagrant::Config.register(directory, config, &code)
    @@vagrant_config_loaded = true
  end
    
  #-----------------------------------------------------------------------------
  # Core plugin type facade
  
  def configuration(options, provider = nil)
    plugin(:CORL, :configuration, provider, options)
  end
  
  def configurations(data, build_hash = false, keep_array = false)
    plugins(:CORL, :configuration, data, build_hash, keep_array)
  end
  
  #-----------------------------------------------------------------------------
  # Cluster plugin type facade
   
  def network(name, options = {}, provider = nil)
    plugin(:CORL, :network, provider, Config.ensure(options).import({ :name => name }))
  end
  
  def networks(data, build_hash = false, keep_array = false)
    plugins(:CORL, :network, data, build_hash, keep_array)
  end
   
  #---
  
  def node(name, options = {}, provider = nil)
    plugin(:CORL, :node, provider, Config.ensure(options).import({ :name => name }))
  end
  
  def nodes(data, build_hash = false, keep_array = false)
    plugins(:CORL, :node, data, build_hash, keep_array)
  end
  
  #---
  
  def builder(options, provider = nil)
    plugin(:CORL, :builder, provider, options)
  end
  
  def builder(data, build_hash = false, keep_array = false)
    plugins(:CORL, :builder, data, build_hash, keep_array)
  end
  
  #---
  
  def provisioner(options, provider = nil)
    plugin(:CORL, :provisioner, provider, options)
  end
  
  def provisioners(data, build_hash = false, keep_array = false)
    plugins(:CORL, :provisioner, data, build_hash, keep_array)
  end
end
end
