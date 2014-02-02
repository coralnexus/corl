
module Coral
module Plugin
class Network < Base
  
  init_plugin_collection 
  
  #-----------------------------------------------------------------------------
  # Cloud plugin interface
  
  def normalize
    super
    
    logger.info("Initializing sub configuration from source with: #{self._export}")
    
    self.config = Coral.configuration(self._export)
    
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
  
  def load
    config.load
  end
  
  def save
    config.save
  end
  
  #---
  
  def add_node(provider, name, options = {})
    # Set node data
    node = set_node(provider, name, options)
    
    unless node.local?
      # Spawn new node
    end
    true    
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
