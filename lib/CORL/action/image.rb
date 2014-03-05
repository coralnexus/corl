
module CORL
module Action
class Image < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure
      
      register :image_nodes, :array, nil do |values|
        if values.nil?
          warn('corl.actions.image.errors.image_nodes_empty')
          next false 
        end
        
        node_plugins = CORL.loaded_plugins(:node)
        success      = true
        
        values.each do |value|
          if info = CORL.plugin_class(:node).translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('corl.actions.image.errors.image_nodes', { :value => value, :node_provider => info[:provider],  :name => info[:name] })
              success = false
            end
          end
        end
        success
      end  
    end
  end
  
  #---
  
  def ignore
    [ :nodes ]
  end
  
  def arguments
    [ :image_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |local_node, network|
      if network
        batch_success = network.batch(settings[:image_nodes], settings[:node_provider], settings[:parallel]) do |node|
          info('corl.actions.image.start', { :provider => node.plugin_provider, :name => node.plugin_name })
          node.create_image
        end
        myself.status = code.batch_error unless batch_success  
      else
        myself.status = code.network_failure
      end    
    end
  end
end
end
end
