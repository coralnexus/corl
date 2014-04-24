
module CORL
module Node
class Vagrant < CORL.plugin_class(:node)
 
  #-----------------------------------------------------------------------------
  # Node plugin interface
   
  def normalize(reload)
    super
    
    unless reload
      machine_provider = :vagrant
      machine_provider = yield if block_given?
                        
      myself.machine = create_machine(:machine, machine_provider, machine_config)
    end
    
    network.ignore([ '.vagrant', 'boxes' ])
    init_shares
  end
       
  #-----------------------------------------------------------------------------
  # Checks
     
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  def state(reset = false)
    machine.state
  end
  
  #---
  
  def vm=vm
    myself[:vm] = vm
  end
  
  def vm
    hash(myself[:vm])
  end
  
  #---
  
  def ssh=ssh
    myself[:ssh] = ssh
  end
  
  def ssh
    hash(myself[:ssh])
  end
  
  #---
    
  def shares=shares
    myself[:shares] = shares
    init_shares
  end
  
  def shares
    hash(myself[:shares])
  end
  
  #---
  
  def build_time=time
    set_cache_setting(:build, time)
  end
  
  def build_time
    cache_setting(:build, nil)
  end
  
  #---
  
  def bootstrap_script=bootstrap
    set_cache_setting(:bootstrap, bootstrap)
  end
  
  def bootstrap_script
    cache_setting(:bootstrap, nil)  
  end
  
  #-----------------------------------------------------------------------------
  # Settings groups
    
  def machine_config
    super do |config|        
      config[:vm]     = vm
      config[:shares] = shares
      
      yield(config) if block_given?
    end
  end
  
  #---
  
  def exec_options(name, options = {})
    extended_config(name, options).export
  end
  
  #-----------------------------------------------------------------------------
  # Node operations
  
  def build(options = {})
    super(Config.ensure(options).import({ :save => false }))  
  end
  
  #---
  
  def create(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:create))
        config[:provision_enabled] = false
      end     
    end
  end
  
  #---
  
  def download(remote_path, local_path, options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:download))
      end
    end
  end
  
  #---
  
  def upload(local_path, remote_path, options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:upload))
      end
    end
  end
  
  #---
  
  def exec(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:exec))
      end
    end
  end
  
  #---
  
  def save(options = {})
    super do
      id(true)
      delete_setting(:machine_type)  
    end  
  end
  
  #---
    
  def start(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:start))
        config[:provision_enabled] = false
      end
    end
  end
  
  #---
    
  def reload(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:reload))
        config[:provision_enabled] = false
      end
    end
  end
  
  #---
  
  def create_image(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:image))
      end
    end
  end
  
  #---
  
  def stop(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:stop))
      elsif op == :finalize
        true
      end
    end
  end
  
  #---

  def destroy(options = {})    
    super do |op, config|
      if op == :config
        config.import(exec_options(:destroy))
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
  def init_shares
    shares.each do |name, info|
      local_dir = info[:local]
      network.ignore(local_dir)      
    end
  end
  
  #---
  
  def filter_output(type, data)
    if type == :error
      if data.include?('stdin: is not a tty') || data.include?('unable to re-open stdin')
        data = ''  
      end
    end
    data  
  end
   
  #-----------------------------------------------------------------------------
  # Machine type utilities
  
  def machine_type_id(machine_type)
    machine_type
  end
  
  #---
  
  def render_machine_type(machine_type)
    machine_type.to_s
  end
  
  #-----------------------------------------------------------------------------
  # Image utilities
  
  def image_id(image)
    image.id
  end
  
  #---
  
  def render_image(image)
    ''  
  end
  
  #---
  
  def image_search_text(image)
    image.to_s
  end    
end
end
end