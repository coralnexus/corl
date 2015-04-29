
module Nucleon
module Action
module Node
class Devkey < Nucleon.plugin_class(:nucleon, :cloud_action)

  include Mixin::Action::Keypair

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :devkey, 530)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      codes :no_password_given

      keypair_config
      config[:require_password].default = true

      register_array :key_nodes, nil do |values|
        if values.nil?
          warn('key_nodes_empty')
          next false
        end

        node_plugins = CORL.loaded_plugins(:CORL, :node)
        success      = true

        values.each do |value|
          if info = CORL.plugin_class(:CORL, :node).translate_reference(value)
            if ! node_plugins.keys.include?(info[:provider].to_sym) || info[:name].empty?
              warn('key_nodes', { :value => value, :node_provider => info[:provider],  :name => info[:name] })
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
    [ :key_nodes ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |local_node|
      ensure_network do
        keypair = keypair(true, false)

        if keypair.nil?
          myself.status = code.no_password_given
        else
          batch_success = network.batch(settings[:key_nodes], settings[:node_provider], false) do |node|
            render_options = { :id => node.id, :hostname => node.hostname }

            info('start', render_options)
            node.attach_keys(keypair)
          end
          if batch_success
            network.save({ :push => true, :remote => :edit })
          else
            myself.status = code.batch_error
          end
        end
      end
    end
  end
end
end
end
end
