
nucleon_require(File.dirname(__FILE__), :node)

#---

module CORL
module Node
class Fog < CORL.plugin_class(:CORL, :node)
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize(reload)
    super
    
    myself.region  = region 
      
    unless reload
      machine_provider = :fog
      machine_provider = yield if block_given?
                        
      myself.machine = create_machine(:machine, machine_provider, machine_config)
    end
  end
       
  #-----------------------------------------------------------------------------
  # Checks
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def api_user=api_user
    myself[:api_user] = api_user
  end
  
  def api_user
    myself[:api_user]
  end
  
  #---
  
  def api_key=api_key
    myself[:api_key] = api_key
  end
  
  def api_key
    myself[:api_key]
  end
  
  #---
  
  def auth_url=auth_url
    myself[:auth_url] = auth_url
  end
  
  def auth_url
    myself[:auth_url]
  end
  
  #---
  
  def connection_options=options
    myself[:connection_options] = options
  end
  
  def connection_options
    myself[:connection_options]
  end
  
  #---
  
  def regions
    []
  end
  
  def region=region
    myself[:region] = region
  end
  
  def region
    if region = myself[:region]
      region
    else
      first_region  = regions.first
      myself.region = first_region
      first_region
    end
  end
  
  #-----------------------------------------------------------------------------
  # Settings groups
    
  def machine_config
    super do |config|        
      config[:connection_options] = connection_options if connection_options
      yield(config) if block_given?
    end
  end
  
  #---
  
  def key_config
    { :private_key_path => private_key, :public_key_path  => public_key }
  end
  
  #---
  
  def exec_options(name, options = {})
    extended_config(name, options).export
  end
  
  #-----------------------------------------------------------------------------
  # Node operations
  
  def create(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:create))
        config.defaults(key_config)
      end
      yield(op, config) if block_given?      
    end
  end
  
  #---
  
  def download(remote_path, local_path, options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:download))
      end
      yield(op, config) if block_given?
    end
  end
  
  #---
  
  def upload(local_path, remote_path, options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:upload))
      end
      yield(op, config) if block_given?
    end
  end
  
  #---
  
  def exec(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:exec))
      end
      yield(op, config) if block_given?
    end
  end
  
  #---
    
  def start(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:start))
        config.defaults(key_config)
      end
      yield(op, config) if block_given?
    end
  end
  
  #---
    
  def reload(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:reload))
      end
      yield(op, config) if block_given?
    end
  end
  
  #---
  
  def create_image(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:image))
      end
      yield(op, config) if block_given?
    end
  end
  
  #---
    
  def stop(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:stop))
      end
      yield(op, config) if block_given?
    end
  end
  
  #---

  def destroy(options = {})    
    super do |op, config|
      if op == :config
        config.import(exec_options(:destroy))
      end
      yield(op, config) if block_given?
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def filter_output(type, data)
    super
  end
end
end
end
