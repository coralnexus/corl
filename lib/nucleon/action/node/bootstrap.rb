
module Nucleon
module Action
module Node
class Bootstrap < CORL.plugin_class(:nucleon, :cloud_action)
  
  #-----------------------------------------------------------------------------
  # Info
  
  def self.describe
    super(:node, :bootstrap, 630)
  end

  #-----------------------------------------------------------------------------
  # Settings
  
  def configure
    super do
      register :auth_files, :array, [] do |values|
        success = true
        values.each do |value|
          unless File.exists?(value)
            warn('corl.actions.bootstrap.errors.auth_files', { :value => value })
            success = false
          end
        end
        success
      end
      register :home_env_var, :str, 'HOME'
      register :home, :str, nil    
      register :bootstrap_path, :str, File.join(CORL.lib_path, '..', 'bootstrap') do |value|
        unless File.directory?(value)
          warn('corl.actions.bootstrap.errors.bootstrap_path', { :value => value })
          next false
        end
        true
      end
      register :bootstrap_glob, :str, '**/*.sh'
      register :bootstrap_init, :str, 'bootstrap.sh'
      
      register :bootstrap_nodes, :array, nil do |values|
        if values.nil?
          warn('corl.actions.bootstrap.errors.bootstrap_nodes_empty')
          next false 
        end
        
        node_plugins = CORL.loaded_plugins(:CORL, :node)
        success      = true
        
        values.each do |value|
          if info = CORL.plugin_class(:CORL, :node).translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('corl.actions.bootstrap.errors.bootstrap_nodes', { :value => value, :node_provider => info[:provider],  :name => info[:name] })
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
    super do |local_node|
      ensure_network do
        batch_success = network.batch(settings[:bootstrap_nodes], settings[:node_provider], settings[:parallel]) do |node|
          render_options = { :id => node.id, :hostname => node.hostname }
          
          info('corl.actions.bootstrap.start', render_options)
          success = node.bootstrap(network.home, extended_config(:bootstrap, settings.clone))
          if success
            info('corl.actions.bootstrap.success', render_options)
          else
            render_options[:status] = node.status
            error('corl.actions.bootstrap.failure', render_options)
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
