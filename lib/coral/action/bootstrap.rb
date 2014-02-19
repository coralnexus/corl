
module Coral
module Action
class Bootstrap < Plugin::Action

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      codes :network_failure
      
      register :auth_files, :array, [] do |values|
        success = true
        values.each do |value|
          unless File.exists?(value)
            warn('coral.actions.bootstrap.errors.auth_files', { :value => value })
            success = false
          end
        end
        success
      end
      register :home_env_var, :str, 'HOME'
      register :home, :str, nil    
      register :bootstrap_path, :str, File.join(Gems.core.full_gem_path, 'bootstrap') do |value|
        unless File.directory?(value)
          warn('coral.actions.bootstrap.errors.bootstrap_path', { :value => value })
          next false
        end
        true
      end
      register :bootstrap_glob, :str, '**/*.sh'
      register :bootstrap_init, :str, 'bootstrap.sh'
      
      register :bootstrap_nodes, :array, nil do |values|
        node_plugins = Manager.connection.loaded_plugins(:node)
        success      = true
        
        values.each do |value|
          if info = Plugin::Node.translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('coral.actions.bootstrap.errors.bootstrap_nodes', { :value => value, :node_provider => info[:provider],  :name => info[:name] })
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
    [ :bootstrap_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations
    
  def execute
    super do |local_node, network|     
      if network
        batch_success = network.batch(settings[:bootstrap_nodes], settings[:node_provider], settings[:parallel]) do |node|
          render_options = { :id => node.id, :hostname => node.hostname }
          
          info('coral.actions.bootstrap.start', render_options)
          node.bootstrap(network.home, extended_config(:bootstrap, settings))
          info('coral.actions.bootstrap.success', render_options)
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
