
module Nucleon
module Action
module Node
class Provision < Nucleon.plugin_class(:nucleon, :cloud_action)

  #-----------------------------------------------------------------------------
  # Info

  def self.describe
    super(:node, :provision, 615)
  end

  #-----------------------------------------------------------------------------
  # Settings

  def configure
    super do
      codes :provision_failure

      register :dry_run, :bool, false
      register :environment, :str, ''
    end
  end

  #---

  def arguments
    [ :environment ]
  end

  #-----------------------------------------------------------------------------
  # Operations

  def execute
    super do |node|
      info('corl.actions.provision.start')

      ensure_node(node) do
        success = true

        settings.delete(:environment) if settings[:environment] == ''

        if settings.has_key?(:environment)
          node.create_fact(:corl_environment, settings[:environment])
        end

        if CORL.admin?
          unless node.build_time && File.directory?(network.build_directory)
            success = node.build(settings)
          end

          if success
            provisioner_info = node.provisioner_info

            node.provisioners.each do |provider, collection|
              provider_info = provisioner_info[provider]
              profiles      = provider_info[:profiles]

              collection.each do |name, provisioner|
                if supported_profiles = provisioner.supported_profiles(node, profiles)
                  profile_success = provisioner.provision(node, supported_profiles, settings)
                  success         = false unless profile_success
                end
              end
            end
            myself.status = code.provision_failure unless success
          end
        end
      end
    end
  end
end
end
end
end
