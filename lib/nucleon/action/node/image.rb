
module Nucleon
module Action
module Node
class Image < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :image, 610)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      register :image_nodes, :array, nil do |values|
        if values.nil?
          warn('corl.actions.image.errors.image_nodes_empty')
          next false
        end

        node_plugins = CORL.loaded_plugins(:CORL, :node)
        success      = true

        values.each do |value|
          if info = CORL.plugin_class(:CORL, :node).translate_reference(value)
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
    super do |local_node|
      ensure_network do
        batch_success = network.batch(settings[:image_nodes], settings[:node_provider], settings[:parallel]) do |node|
          info('start', { :provider => node.plugin_provider, :name => node.plugin_name })
          success = node.create_image
          success('complete', { :provider => node.plugin_provider, :name => node.plugin_name }) if success
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
