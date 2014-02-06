
module Coral
module Node
class Fog < Plugin::Node
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize
    super
    self.region = region
    
    yield if block_given?
    create_machine(:fog, extended_config(:machine, provider_info))
  end
       
  #-----------------------------------------------------------------------------
  # Checks
  
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def user_name=user_name
    set(:user_name, nil)
  end
  
  def user_name
    get(:user_name, nil)
  end
  
  #---
  
  def api_key=api_key
    set(:api_key, api_key)
  end
  
  def api_key
    get(:api_key, nil)
  end
  
  #---
  
  def auth_url=auth_url
    set(:auth_url, auth_url)
  end
  
  def auth_url
    get(:auth_url, nil)
  end
  
  #---
  
  def connection_options=options
    set(:connection_options, options)
  end
  
  def connection_options
    get(:connection_options, nil)
  end
  
  #---
  
  def regions
    []
  end
  
  def region=region
    set(:region, region)
  end
  
  def region
    if region = get(:region, nil)
      region
    else
      first_region = regions.first
      self.region  = first_region
      first_region
    end
  end
  
  #-----------------------------------------------------------------------------
  # Settings groups
    
  def provider_info
    config = Config.new({ :name => get(:id, get(:hostname, nil), nil) })
        
    config[:connection_options] = connection_options if connection_options
    
    yield(config) if block_given?
    config.export
  end
  
  #---
  
  def exec_options(name)
    extended_config(name, {}).export
  end
  
  #-----------------------------------------------------------------------------
  # Node operations
  
  def create(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:create))
      end
      yield(op, config) if block_given?
    end
  end
  
  #---
    
  def start(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:start))
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
    
  def reload(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:reload))
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

  #---
  
  def exec(commands, options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:exec))
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
  
  #-----------------------------------------------------------------------------
  # Utilities
  
end
end
end
