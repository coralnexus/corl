
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

      register_bool :build, false
      register_bool :dry_run, false
      register_bool :check_profiles, false

      register_str :environment
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
      ensure_node(node) do
        success = true

        settings.delete(:environment) if settings[:environment] == ''

        if settings.has_key?(:environment)
          CORL.create_fact(:corl_environment, settings[:environment])
        end

        if CORL.admin?
          unless settings[:check_profiles]
            info('start', { :provider => node.plugin_provider, :name => node.plugin_name })
          end

          if settings[:build] ||
            settings.has_key?(:environment) ||
            ! ( node.build_time && File.directory?(network.build_directory) )

            info('build', { :provider => node.plugin_provider, :name => node.plugin_name })
            success = node.build(settings)
          end

          if success
            provisioner_info = node.provisioner_info

            node.provisioners.each do |provider, collection|
              provider_info = provisioner_info[provider]
              profiles      = provider_info[:profiles]

              collection.each do |name, provisioner|
                if supported_profiles = provisioner.supported_profiles(node, profiles)
                  supported_profiles.each do |profile|
                    info('profile', { :provider => yellow(provider), :profile => green(profile.to_s) })
                  end
                  unless settings[:check_profiles]
                    profile_success = provisioner.provision(node, supported_profiles, settings)
                    success         = false unless profile_success
                  end
                end
              end
            end
            unless settings[:check_profiles]
              success('complete', { :provider => node.plugin_provider, :name => node.plugin_name, :time => Time.now.to_s }) if success
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
