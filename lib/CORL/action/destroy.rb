
module CORL
module Action
class Destroy < Plugin::CloudAction
 
  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :destroy_nodes, :array, nil do |values|
        if values.nil?
          warn('corl.actions.destroy.errors.destroy_nodes_empty')
          next false 
        end
        
        node_plugins = CORL.loaded_plugins(:node)
        success      = true
        
        values.each do |value|
          if info = CORL.plugin_class(:node).translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('corl.actions.destroy.errors.destroy_nodes', { :value => value, :node_provider => info[:provider],  :name => info[:name] })
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
    [ :destroy_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations
   
  def execute
    super do |local_node, network|
      ensure_network(network) do
        batch_success = network.batch(settings[:destroy_nodes], settings[:node_provider], settings[:parallel]) do |node|
          info('corl.actions.stop.start', { :provider => node.plugin_provider, :name => node.plugin_name })
          node.destroy
        end
        myself.status = code.batch_error unless batch_success
      end
    end
  end
end
end
end
