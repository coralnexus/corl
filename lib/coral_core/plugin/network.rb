
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
    node_config(provider).export.empty? ? false : true
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
  
  def node_groups
    groups = {}
    
    each_node_config! do |provider, name, info|
      search_node(provider, name, :groups, [], :array).each do |group|
        group = group.to_sym
        groups[group] = [] unless groups.has_key?(group)
        groups[group] << { :provider => provider, :name => node_name }
      end
    end    
    groups
  end
  
  #---
  
  def node_info(references, default_provider = nil)
    groups    = node_groups
    node_info = {}
    
    default_provider = Plugin.type_default(:node) if default_provider.nil?
        
    references.each do |reference|
      info = Plugin::Node.translate_reference(reference)
      info = { :provider => default_provider, :name => reference } unless info
      name = info[:name].to_sym     
      
      # Check for group membership
      if groups.has_key?(name)
        groups[name].each do |member_info|
          provider = member_info[:provider].to_sym
          
          node_info[provider] = [] unless node_info.has_key?(provider)        
          node_info[provider] << member_info[:name]
        end
      else
        # Not a group
        provider = info[:provider].to_sym
        
        if node_config.export.has_key?(provider)
          node_found = false
          
          each_node_config!(provider) do |node_provider, node_name, node|
            if node_name == name
              node_info[node_provider] = [] unless node_info.has_key?(node_provider)        
              node_info[node_provider] << node_name
              node_found = true
              break
            end
          end
          
          unless node_found
            # TODO:  Error or something?
          end
        end 
      end     
    end    
    node_info  
  end
  
  #---
  
  def node_by_ip(public_ip)
    each_node_config! do |provider, name, info|
      return node(provider, name) if info[:public_ip] == public_ip  
    end
    nil
  end
  
  #---
  
  def local_node
    ip_address = lookup(:ipaddress)
    local_node = node_by_ip(ip_address)
        
    if local_node.nil?
      name       = Util::Data.ensure_value(lookup(:hostname), ip_address)    
      local_node = Coral.node(name, extended_config(:local_node).import({ :meta => { :parent => self }}), :local) 
    else
      local_node.localize               
    end    
    local_node
  end
  
  #---
  
  def nodes_by_reference(references, default_provider = nil)
    nodes = []
    
    node_info(references, default_provider).each do |provider, names|
      names.each do |name|
        nodes << node(provider, name)
      end
    end
    nodes  
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

  def each_node_config!(provider = nil)
    node_config.export.each do |node_provider, nodes|
      if provider.nil? || provider == node_provider
        nodes.each do |name, info|
          yield(node_provider, name, info)
        end
      end
    end
  end
  
  #---
  
  def batch(node_references, default_provider = nil, parallel = true)
    success = true
    
    if has_nodes? && ! node_references.empty?
      # Execute action on remote nodes      
      nodes = nodes_by_reference(node_references, default_provider)
      
      Coral.batch(parallel) do |batch_op, batch|
        if batch_op == :add
          # Add batch operations      
          nodes.each do |node|
            batch.add(node.name) do
              ui_group!(node.hostname) do
                yield(node) if block_given?
              end  
            end
          end
        else
          # Reduce to single status
          batch.each do |name, process_success|
            unless process_success
              success = false
              break
            end
          end
        end
      end
    end
    success
  end
end
end
end
