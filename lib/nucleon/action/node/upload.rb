
module Nucleon
module Action
module Node
class Upload < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :upload, 500)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      register_str :local_path, nil
      register_str :remote_path, nil
      register_str :file_mode, '0755'

      register_bool :progress, true

      register_array :upload_nodes, nil do |values|
        if values.nil?
          warn('upload_nodes_empty')
          next false
        end

        node_plugins = CORL.loaded_plugins(:CORL, :node)
        success      = true

        values.each do |value|
          if info = CORL.plugin_class(:CORL, :node).translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('upload_nodes', { :value => value, :node_provider => info[:provider],  :name => info[:name] })
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
    [ :local_path, :remote_path, :upload_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |local_node|
      ensure_network do
        batch_success = network.batch(settings[:upload_nodes], settings[:node_provider], settings[:parallel]) do |node|
          render_options = { :id => node.id, :hostname => node.hostname, :local_path => settings[:local_path], :remote_path => settings[:remote_path] }

          info('start', render_options)
          success = node.send_files(settings[:local_path], settings[:remote_path], nil, settings[:file_mode], { :progress => settings[:progress] })

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
