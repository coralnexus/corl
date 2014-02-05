
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
    
    init_nodes
  end
  
  #-----------------------------------------------------------------------------
  # Checks
  
  def has_nodes?(provider = nil)
    return nodes(provider).empty? ? false : true
  end
       
  #-----------------------------------------------------------------------------
  # Property accessors / modifiers
  
  plugin_collection :node
  
  #-----------------------------------------------------------------------------
  # Operations
  
  def load(options = {})
    config.load(options)
  end
  
  def save(options = {})
    config.save(options)
  end
  
  #---
  
  def add_node(provider, name, options = {})
    # Set node data
    node    = set_node(provider, name, options)
    success = true
    
    unless node.local?
      if node.create
        node.delete_setting(:name) # @TODO: This should really be researched and fixed
        
        node.set_setting(:id, string(node.id))
        node.set_setting(:region, string(node.region))
        node.set_setting(:machine_type, string(node.machine_type))
        node.set_setting(:hostname, node.hostname)
        node.set_setting(:public_ip, node.public_ip)
        node.set_setting(:private_ip, node.private_ip)
        
        ssh_keys    = []
        private_key = config.attach(:keys, node.name, options[:private_key]) if options[:private_key]
        public_key  = config.attach(:keys, node.name, options[:public_key]) if options[:public_key]
        
        unless private_key.nil?
          ssh_keys << private_key       
          node.set_setting(:private_key, private_key)
        end
        unless public_key.nil?
          ssh_keys << public_key
          node.set_setting(:public_key, public_key)
        end
        
        dbg(config.export, 'configuration export')
        
        save({ :files => ssh_keys, :commit => true, :remote => nil })
        
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
end
end
end
