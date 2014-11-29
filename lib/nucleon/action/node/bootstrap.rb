
module Nucleon
module Action
module Node
class Bootstrap < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :bootstrap, 630)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      register_directory :bootstrap_path, File.join(CORL.lib_path, '..', 'bootstrap')
      register_files :auth_files

      register_bool :reboot, false

      register_str :home_env_var, 'HOME'
      register_str :home, nil

      register_str :bootstrap_glob, '**/*.sh'
      register_str :bootstrap_init, 'bootstrap.sh'

      register_array :bootstrap_scripts

      register_array :bootstrap_nodes, nil do |values|
        if values.nil?
          warn('bootstrap_nodes_empty')
          next false
        end

        node_plugins = CORL.loaded_plugins(:CORL, :node)
        success      = true

        values.each do |value|
          if info = CORL.plugin_class(:CORL, :node).translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('bootstrap_nodes', { :value => value, :node_provider => info[:provider],  :name => info[:name] })
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

          info('start', render_options)
          success = node.bootstrap(network.home, extended_config(:bootstrap, Util::Data.clone(settings)))
          if success
            success('complete', render_options)
          else
            render_options[:status] = node.status
            error('failure', render_options)
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
