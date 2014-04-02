
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
  
  def create(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:create))
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
      end
    end
  end
  
  #---
    
  def reload(options = {})
    super do |op, config|
      if op == :config
        config.import(exec_options(:reload))
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
end
end
end