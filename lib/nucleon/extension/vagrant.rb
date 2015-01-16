
module Nucleon
module Extension
class Vagrant < Nucleon.plugin_class(:nucleon, :extension)

  def network_new_node_config(config)
    plugin   = config[:plugin]
    provider = plugin.plugin_provider

    if provider == :vagrant
      image_name   = string(config.delete(:image))
      machine_type = symbol(config.delete(:machine_type))
      hostname     = string(config[:hostname])

      public_ip    = string(config.delete(:public_ip))

      case machine_type
      when :docker
        config.set([ :vm, :providers, :docker, :image ], image_name)
      else
        config.set([ :vm, :providers, machine_type, :private_network ], public_ip) if public_ip
        config.set([ :vm, :providers, machine_type, :override, :vm, :box ], image_name)
      end

      config.set([ :vm, :providers, :docker, :create_args ], [ "--hostname='#{hostname}'" ])
    end
  end
end
end
end
