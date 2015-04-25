
module Nucleon
module Action
module Node
class Download < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :download, 500)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      register_str :remote_path, nil
      register_str :local_path, nil

      register_bool :progress, true

      register_array :download_nodes, nil do |values|
        if values.nil?
          warn('download_nodes_empty')
          next false
        end

        node_plugins = CORL.loaded_plugins(:CORL, :node)
        success      = true

        values.each do |value|
          if info = CORL.plugin_class(:CORL, :node).translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('download_nodes', { :value => value, :node_provider => info[:provider],  :name => info[:name] })
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
    [ :nodes, :parallel ]
  end

  def arguments
    [ :remote_path, :local_path, :upload_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |local_node|
      ensure_network do
        batch_success = network.batch(settings[:download_nodes], settings[:node_provider], false) do |node|
          render_options = { :id => node.id, :hostname => node.hostname, :remote_path => settings[:remote_path], :local_path => settings[:local_path] }

          info('start', render_options)
          success = node.download(settings[:remote_path], settings[:local_path], { :progress => settings[:progress] })

          if success
            success('complete', render_options)
          else
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
