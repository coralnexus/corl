
module Nucleon
module Plugin
class Network < CORL.plugin_class(:base)
  
  init_plugin_collection 
  
  #-----------------------------------------------------------------------------
  # Cloud plugin interface
  
  def normalize(reload)
    super
    
    logger.info("Initializing sub configuration from source with: #{myself._export.inspect}")
    myself.config = CORL.configuration(Config.new(myself._export).import({ :autosave => false })) unless reload
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
  
  def home
    extension_set(:home, ( ENV['USER'] == 'root' ? '/root' : ENV['HOME'] )) 
  end
  
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
    
    each_node_config do |provider, name, info|
      search_node(provider, name, :groups, [], :array).each do |group|
        group = group.to_sym
        groups[group] = [] unless groups.has_key?(group)
        groups[group] << { :provider => provider, :name => name }
      end
    end
    groups
  end
  
  #---
  
  def node_info(references, default_provider = nil)
    groups    = node_groups
    node_info = {}
    
    default_provider = Manager.connection.type_default(:node) if default_provider.nil?
        
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
          
          each_node_config(provider) do |node_provider, node_name, node|
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
    each_node_config do |provider, name, info|
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
      local_node = CORL.node(name, extended_config(:local_node).import({ :meta => { :parent => myself }}), :local) 
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
  
  #---
  
  def test_node(provider)
    CORL.node(:test, { :meta => { :parent => myself } }, provider)
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
  
  def attach_files(type, name, files, options = {})
    attach_config  = Config.ensure(options).import({ :type => :file })
    included_files = []    
    files          = [ files ] unless files.is_a?(Array)
    
    files.each do |file|
      if file
        attached_file = config.attach(type, name, file, attach_config)
        included_files << attached_file unless attached_file.nil?
      end  
    end    
    included_files
  end
  
  #---
  
  def attach_data(type, name, data, options = {})
    attach_config = Config.ensure(options).import({ :type => :source })
    attached_data = nil    
    
    if data.is_a?(String)
      attached_data = config.attach(type, name, data, attach_config)
    end  
    attached_data
  end
  
  #---
  
  def attach_keys(node, keypair)
    base_name   = "#{node.plugin_provider}-#{node.plugin_name}"
    save_config = { :pull => false, :push => false }
        
    private_key = attach_data(:keys, "#{base_name}-id_#{keypair.type}", keypair.encrypted_key)
    public_key  = attach_data(:keys, "#{base_name}-id_#{keypair.type}.pub", keypair.ssh_key)
    
    if private_key && public_key
      FileUtils.chmod(0600, private_key)
      FileUtils.chmod(0644, public_key)
      
      save_config[:files] = [ private_key, public_key ]
    
      node[:private_key] = private_key
      node[:public_key]  = public_key
    
      save_config[:message] = "Updating SSH keys for node #{node.plugin_provider} (#{node.plugin_name})"    
      node.save(extended_config(:key_save, save_config))
    else
      false
    end
  end
  
  #---
  
  execute_block_on_receiver :add_node
  
  def add_node(provider, name, options = {})
    config = Config.ensure(options)
    
    keypair = config.delete(:keypair, nil)
    return false unless keypair && keypair.is_a?(Util::SSH::Keypair)
        
    remote_name = config.delete(:remote, :edit)
    
    # Set node data
    node        = set_node(provider, name, {})
    hook_config = { :node => node, :remote => remote_name, :config => config }
    success     = true
    
    yield(:preprocess, hook_config) if block_given?
    
    if ! node.local? && attach_keys(node, keypair) && extension_check(:add_node, hook_config)
      node[:hostname] = name
      node[:image]    = config[:image]
          
      # Create new node / machine
      success = node.create do |op, data|
        block_given? ? yield("create_#{op}".to_sym, data) : data
      end
      
      if success && node.save({ :remote => remote_name, :message => "Created machine #{name} on #{provider}" })
        # Bootstrap new machine
        success = node.bootstrap(home, extended_config(:bootstrap, config)) do |op, data|
          block_given? ? yield("bootstrap_#{op}".to_sym, data) : data
        end  
        
        if success
          seed_project = config.get(:project_reference, nil)
          save_config  = { :commit => true, :remote => remote_name, :push => true }
               
          if seed_project && remote_name
            # Reset project remote
            seed_info = Plugin::Project.translate_reference(seed_project)
          
            if seed_info
              seed_url    = seed_info[:url]
              seed_branch = seed_info[:revision] if seed_info[:revision]
            else
              seed_url = seed_project                
            end
            set_remote(:origin, seed_url) if remote_name.to_sym == :edit
            set_remote(remote_name, seed_url)
            save_config[:pull] = false
          end
          
          # Save network changes (preliminary)
          success = node.save(extended_config(:node_save, save_config))
        
          if success && seed_project
            # Seed machine with remote project reference
            result = node.seed({
              :net_provider      => plugin_provider,
              :project_reference => seed_project,
              :project_branch    => seed_branch
            }) do |op, data|
              yield("seed_#{op}".to_sym, data)
            end
            success = result.status == code.success
          end
        
          # Update local network project
          success = load({ :remote => remote_name, :pull => true }) if success
        end
      end
    end    
    success 
  end
  
  #---
  
  def remove_node(provider, name = nil)
    status = CORL.code.success
    
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
      
      if status == CORL.code.success
        delete_node(provider, name)
      else
        ui.warn("Stopping #{provider} node #{name} failed")
      end       
    end  
        
    status
  end
  
  #-----------------------------------------------------------------------------
  # Utilities

  def each_node_config(provider = nil)
    node_config.export.each do |node_provider, nodes|
      if provider.nil? || provider == node_provider
        nodes.each do |name, info|
          yield(node_provider, name, info)
        end
      end
    end
  end
  
  #---
  
  execute_block_on_receiver :batch
  
  def batch(node_references, default_provider = nil, parallel = true, &code)
    success = true
    
    if has_nodes? && ! node_references.empty?
      # Execute action on selected nodes      
      nodes = nodes_by_reference(node_references, default_provider)
      
      if parallel
        values = []
        nodes.each do |node|
          values << Celluloid::Future.new(node, &code)
        end
        values  = values.map { |future| future.value }
        success = false if values.include?(false)
      else
        nodes.each do |node|
          proc_success = code.call(node)
          if proc_success == false
            success = false
            break
          end
        end  
      end
    end
    success
  end
end
end
end
