
module Coral
module Plugin
class Network < Base
  
  init_plugin_collection 
  
  #-----------------------------------------------------------------------------
  # Cloud plugin interface
  
  def normalize
    super
    
    logger.info("Initializing sub configuration from source with: #{self._export}")
    
    self.config = Coral.configuration(Config.new(self._export).import({ :autocommit => false }))
  end
  
  #-----------------------------------------------------------------------------
  # Checks
  
  def has_nodes?(provider = nil)
    return nodes(provider).empty? ? false : true
  end
       
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  plugin_collection :node
  
  #---
  
  def remote(name)
    config.remote(name)
  end
  
  def set_remote(name, location)
    config.set_remote(name, location)
  end
  
  #---
  
  def node_by_ip(public_ip)
    each_node! do |provider, node_name, node|
      return node if node.public_ip == public_ip  
    end
    return nil
  end
  
  #-----------------------------------------------------------------------------
  # Operations
  
  def load(options = {})
    config.load(options)
  end
  
  #---
  
  def save(options = {})
    config.save(options)
  end
  
  #---
  
  def attach(type, name, files, options = {})
    included_files = []    
    files          = [ files ] unless files.is_a?(Array)
    
    files.each do |file|
      if file
        attached_file = config.attach(type, name, file, options)
        included_files << attached_file unless attached_file.nil?
      end  
    end    
    included_files
  end
  
  #---
  
  def add_node(provider, name, options = {})
    config = Config.ensure(options)
        
    remote_name  = config.delete(:remote, :edit)
    seed_project = config.delete(:seed, nil)
    
    # Set node data
    node    = set_node(provider, name, config)
    success = true
    
    unless node.local?
      if node.create
        save_config = { :commit => true, :remote => remote_name, :push => true }
        
        node.delete_setting(:name) # @TODO: This should really be researched and fixed
        
        node[:id]           = string(node.id)
        node[:region]       = string(node.region)
        node[:machine_type] = string(node.machine_type)
        node[:hostname]     = node.hostname
        node[:public_ip]    = node.public_ip
        node[:private_ip]   = node.private_ip
        
        ssh_keys = attach(:keys, node.public_ip, [ config[:private_key], config[:public_key] ])
        
        if ssh_keys.length == 2 && ssh_keys[0] && ssh_keys[1]
          node[:private_key]  = ssh_keys[0]
          node[:public_key]   = ssh_keys[1]
                    
          save_config[:files] = ssh_keys
        else
          ssh_keys = []
        end
        
        if seed_project && remote_name
          set_remote(:origin, seed_project) if remote_name.to_sym == :edit
          set_remote(remote_name, seed_project)
          save_config[:pull] = false
        end
        
        success = save(save_config)
        
        # 2. Bootstrap new machine
        # 3. Seed machine with remote project reference
        # 4. Save machine to network project
        # 5. Update local network project
      end
    end
    
    success 
  end
  
  #---
  
  def remove_node(provider, name = nil)
    status = Coral.code.success
    
    if name.nil?
      nodes(provider).each do |node_name, node|
        sub_status = remove_node(provider, node_name)
        status     = sub_status unless status == sub_status 
      end  
    else
      node = node(provider, name)
      
      unless node.local?  
        # Stop node
        status = node.run(:stop)
      end
      
      if status == Coral.code.success
        delete_node(provider, name)
      else
        ui.warn("Stopping #{provider} node #{name} failed")
      end       
    end  
        
    status
  end
  
  #-----------------------------------------------------------------------------
  # Utilities
  
end
end
end
