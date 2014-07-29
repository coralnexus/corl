
module Nucleon
module Action
module Node
class SSH < Nucleon.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :ssh, 560)
  end

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :ssh_nodes, :array, nil do |values|
        if values.nil?
          warn('corl.actions.bootstrap.errors.ssh_nodes_empty')
          next false 
        end
        
        node_plugins = CORL.loaded_plugins(:CORL, :node)
        success      = true
        
        values.each do |value|
          if info = CORL.plugin_class(:CORL, :node).translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('corl.actions.bootstrap.errors.ssh_nodes', { :value => value, :node_provider => info[:provider],  :name => info[:name] })
              success = false
            end
          end
        end
        success
      end      
    end
    config[:node_provider].default = :rackspace
  end
  
  #---
  
  def ignore
    node_ignore - [ :net_provider, :node_provider ]
  end
  
  def arguments
    [ :ssh_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations
    
  def execute
    super do |local_node|
      ensure_network do
        batch_success = network.batch(settings[:ssh_nodes], settings[:node_provider], false) do |node|
          render_options = { :id => node.id, :hostname => node.hostname }
          
          info('corl.actions.ssh.start', render_options)
          success = node.terminal(extended_config(:ssh, {}))
          if success
            info('corl.actions.ssh.success', render_options)
          else
            render_options[:status] = node.status
            error('corl.actions.ssh.failure', render_options)
          end
          success
        end
        myself.status = code.batch_error unless batch_success
      end
    end
  end
end
end
end
end
